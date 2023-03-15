# Entendendo e Criando Docker Container Actions

Actions são tasks individuais que podem ser combinadas para criar jobs e customizar workflows, ajudando a diminuir a quantidade repetitiva de código. Você pode utilizar as actions publicadas no GitHub Marketplace ou criar e customizar suas próprias actions.

O GitHub Actions permite criar 3 tipos de actions customizadas: Javascript, Composite e Docker container. Nesse artigo, vamos entender sobre Docker Container Actions, como implementar sua primeira Docker action e testá-la em um GitHub workflow.

## Docker Container Action

Docker Container permite que você crie actions customizadas empacotando o ambiente com o código da action. Dessa forma, quem consumir sua action não precisa se preocupar com as dependências necessárias para executá-la, basta referenciar a action em seu workflow e executar, pois ela já conterá todos os componentes necessários para execução.

### Quando usar Docker container action?

Docker container action é a opção ideal para actions que precisam ser executadas em ambientes com configurações específicas, já que permite personalizar o sistema operacional, as ferramentas, código e dependências sem necessitar adicionar ao runner, basta apenas o runner possuir o Docker e é possível executar no mesmo runner diversas Docker actions e cada uma com sua personalização.

Você também pode utilizar Docker Container quando Javascript actions não for uma opção, seja por querer utilizar uma versão específica do Node, já que Javascript actions utilizam Node(12) ou até mesmo por familiaridade com outras linguagens, já que com Docker container é possível construir actions utilizando suas linguagens favoritas, seja Python, Go, Bash, Ruby e entre outras.

## Criando Docker container actions

Agora vamos entender e executar os passos necessários para criar um Docker container, e teremos então uma docker container action desenvolvida em Python que faz uma chamada a API do GitHub para listar branches de um repositório público.

### Pré requisitos

- **SO Linux e Docker:** Para rodar Docker container actions, os Self-hosted runners precisam utilizar o sistema operacional Linux e ter o Docker instalado, mas você pode utilizar os GitHub-hosted runners, que são gerenciados pelo GitHub e já possuem o Docker, como por exemplo `ubuntu-latest`.

- **Repositório:** Antes de iniciar, é necessário criar um repositório GitHub.

    1. **Crie um novo repositório GitHub:**  Estarei utilizando ``list-branches-docker-action`` como nome do repositório, mas você pode criar com o nome que preferir. Para informações de criação de repositórios, consulte: [Criando um novo repositório](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository).

    2. **Clone o repositório:** após criar o repositório, clone em sua máquina. Saiba mais em: [Clonando repositório](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository).

    3. **Mude o diretório:** Em seu terminal, execute o comando a seguir para mudar o diretório para o novo repositório:

    ```bash
        cd list-branches-docker-action
    ```

### Implementando código da action

No diretório raiz `list-branches-docker-action`, vamos criar o arquivo `main.py` que conterá o código escrito em python que a action irá executar:

```python
# Código da action
import requests
import json
import sys

r=requests.get("https://api.github.com/repos/"+sys.argv[1]+"/"+sys.argv[2]+"/branches", headers={"Accept": "application/vnd.github+json" ,"X-GitHub-Api-Version":"2022-11-28"})

objeto = json.loads(r.text)

print("\nLista de branches do repositório "+sys.argv[2]+ " :")
for v in objeto:
    print(v['name'])
```

Esse script faz uma chamada a API do GitHub `https://api.github.com/repos/OWNER/REPO/branches`, que recebe dois parâmetros: `OWNER`, representando o owner do repositório e `REPO`, que representa o nome do repositório do qual iremos listar as branches.

Para fazer essa chamada, inicialmente importamos os módulos necessárias. Sendo `requests`, que possibilita realizarmos requests http, `json` para trabalharmos com os dados JSON e `sys` para manipularmos os parâmetros que são passados na execução do programa.

Onde fazemos a chamada da request, substituímos os argumentos `OWNER` e `REPO` por `sys.argv[1]` e `sys.argv[2]` correspondente, pois esses parâmetros serão atualizados com os valores passados como argumento para o container.

Por fim, convertemos o json da resposta da API em um objeto Python Dictionary para conseguirmos percorrer esse objeto e trazer apenas o nome das branches.

### Criando o Dockerfile

Com o código da action definido, seguindo a sintaxe e os padrões descritos em [Suporte do arquivo Docker para GitHub Actions](https://docs.github.com/pt/actions/creating-actions/dockerfile-support-for-github-actions) criamos o arquivo `Dockerfile` que será utilizado para criar a imagem que conterá o código da action.

```dockerfile
#Imagem de container que executa o código da action
FROM python:3.8-alpine

RUN pip install requests

COPY main.py /main.py

ENTRYPOINT ["python", "/main.py"]
```

Estamos utilizando `python:3.8-alpine` como base para nossa imagem, pois já inclui o Python. Com o comando `RUN pip install requests` Instalamos as bibliotecas necessárias para execução da action que são importadas no arquivo `main.py` e ao final do arquivo em `ENTRYPOINT ["python", "/main.py"]` adicionamos uma instrução para que o Docker execute o arquivo `main.py` assim que iniciar o container.

>Note que estamos apenas instalando a biblioteca requests, pois json e sys são pacotes que já vêm integrado com o Python.

### Criando arquivo de metadados da action

No diretório `list-branches-docker-action`, criamos um arquivo `action.yml` que contém toda a definição da action, como descrição, inputs e outputs.

```yml
#action.yml
name: 'List Branches Docker Action'
description: 'Lista branches de um repositório público'
inputs:
  owner: # id do input
    description: 'Sua organização ou usuário github'
    required: true
  repo: # id do input
    description: 'Nome do repositório' # que possui as branches a serem listadas
    required: true
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.owner }}
    - ${{ inputs.repo }} 
```

No `action.yml` acima, setamos o nome, descrição da action e também o ícone e a cor que representará a action caso deseje publicar no Github Marketplace.

#### Passando Inputs para o container

Para passar os argumentos para o Docker container, precisamos declarar os `inputs` e então passá-los como argumento usando `args`. Em nosso arquivo, temos os inputs obrigatórios `owner` e `repo`, que são passados  como argumentos ``inputs.owner``  e `inputs.repo`, pois serão utilizados para atualizar os parâmetros `sys.args[1]` e `sys.argv[2]` definidos em nosso arquivo `main.py`.

```yml
inputs:
  owner: # id do input
    description: 'sua organização ou usuário GitHub'
    required: true
  repo: # id do input
    description: 'nome do repositório' # que possui as branches a serem listadas
    required: true
```

```yml
runs:
  args:
    - ${{ inputs.owner }}
    - ${{ inputs.repo }} 
```

#### Definindo a imagem da action

Precisamos especificar a imagem que será utilizada para iniciar o container que contém o código da action. Na sessão `run` passamos a propriedade `using` como `docker` e podemos definir a imagem de 2 formas:

1. Usando o arquivo Dockerfile presente no repositório da action:

    ```yml
    runs:
      using: 'docker'
      image: 'Dockerfile'
    ```

    Assim como em nosso `action.yml`, quando passamos `Dockerfile` em `image`, o GitHub runner construirá  uma imagem a partir desse Dockerfile e iniciará um container que executará o código definido em main.py.

2. Usando uma imagem de um  Docker registry:

    ```yml
    runs: 
      using: 'docker'
      image: 'docker://geovana10/list-branches-docker-action:v1'
    ```

    Ao utilizar uma imagem de um Docker registry, o Github runner não precisa construí-la e apenas realiza o pull dessa imagem, buscando ela e executando-a para inciar o container contendo o código da action.

> Devido a latência que o runner tem de construir e recuperar a imagem, as Docker Actions costumam ser mais lentas que Javascript actions.

### Adicionando tag e realizando push da action para o repositório do github

Após a criação dos arquivos `main.py`, `Dockerfile` e `action.yml`, podemos fazer o commit, realizar o push para nosso repositório do GitHub e adicionar uma annotated tag, que será utilizada posteriormente para identificar a versão da nossa action. No diretório local `list-branches-docker-action`, execute:

```bash
git add .
git commit -m "my actions file"
git tag -a v1 -m "Primeira versão list branches tag"
git push --follow-tags
```

### Testando a Docker container action em um GitHub Workflow

Com a action disponível em nosso repositório, já podemos testá-la em um GitHub workflow. As actions públicas podem ser utilizadas em qualquer repositório, mas podemos ter actions em repositório privado onde podemos controlar o acesso e também podemos publicá-las no Github Marketplace. Para mais informações, veja [Publicar actions no GitHub Marketplace](https://docs.github.com/pt/actions/creating-actions/publishing-actions-in-github-marketplace)

Para usarmos a action, precisamos ter um arquivo .yml no diretório `.github/workflows`, então nesse diretório criamos o arquivo `main.yml`, que é executado sempre que for realizado um push na branch master do repositório.

```yml
on: [push]

jobs:
  List-Branches:
    runs-on: ubuntu-latest
    name: Job para listar Branches de repositório GitHub
    steps:
      - name: Listar Branches action step
        id: list
        uses: geovanams/list-branches-docker-action@v1
        with:
          owner: 'geovanams'
          repo: 'public-repo'
```

Esse workflow possui um único job chamado “List-Branches” que executará o step “List Branches action step”. Nesse step em `uses` chamamos a action que criamos anteriormente.

Como a actions está em um repositório público, estamos definindo a action usando a seguinte sintaxe: `geovanams/list-docker-action@v1`, que você pode substituir com as suas informações, onde temos o nome do owner ou organização, em seguida o nome do repositório e então `@v1` representando a versão da action, que corresponde a tag que criamos anteriormente, mas podemos versionar usando commit ID ou até mesmo o nome da branch. Para mais informações sobre como gerenciar versão de actions com tags e releases, visite: [Melhores práticas para gerenciamento de versões](https://docs.github.com/en/actions/creating-actions/about-custom-actions#good-practices-for-release-management)

Para passarmos os parâmetros da action, utilizamos o atributo `with`. Nesse workflow, passamos os parâmetros `owner` e `repo` que você pode substituir os valores pelo owner e nome do repositório do qual deseja listar as branches.

```yml
uses: geovanams/list-branches-docker-action@v1
with:
    owner: 'geovanams'
    repo: 'public-repo'
```

Após salvar o arquivo no repositório, o GitHub já iniciará o workflow. Na aba **Actions**, podemos ver os logs de execução dos jobs e steps do workflow.

[image]

<img width="1400" alt="imgarticle" src="https://user-images.githubusercontent.com/50850895/225105797-c5554081-bc36-4424-9fc0-fcbe05c58342.png">

Note que temos 2 steps principais:

**Build geovanams/list-branches-docker-action@v1:** Como definimos `Dockerfile` em nosso arquivo `action.yml`, o GitHub adicionou esse step de **build** para construir a imagem a partir do arquivo Dockerfile presente no repositório.

[image]

Como dito anteriormente, se utilizarmos a imagem de um Docker registry, para recuperar a imagem o GitHub adicionaria o step de pull ao invés do de build. Exemplo:

[image]

**List Branch action step:** Esse é o step que de fato chamamos a docker action, ele mostra os parâmetros passados para action e o resultado de sua execução, listando então todas as branches do repositório definido.

[image]

## Criando README

Criar um README é uma ótima maneira de definir como as pessoas devem utilizar suas actions. No diretório raiz `list-branches-docker-action` criamos o arquivo `README.md`, que contêm as informações necessárias de como utilizar a action que criamos.

```md
# List Branches Docker Action
Essa action lista as branches de um repositório público.

## Inputs

## `owner`

**Required** Sua organização ou usuário GitHub que possui o repositório do qual deseja listar.

## `repo`

**Required** nome do repositório que possui as branches a ser listadas.

## Example usage

uses: geovanams/list-branches-docker-action@v1
with:
  owner: 'geovanams'
  repo: 'public-repo'
```

### Estrutura de arquivos do repositório

Ao concluir os passos anteriores, teremos então um repositório estruturado da seguinte forma:

```bash
.
├── .github/workflows
│   └── main.yml
├── Dockerfile
├── README.md
├── action.yml
└── main.py
```

Você pode baixar essa estrutura com o código completo da docker action do repositório GitHub [List-Branches-Docker-Action](https://docs.github.com/en/actions/creating-actions/about-custom-actions).

## Conclusões

GitHub Docker action é uma ótima escolha para criação de actions customizadas que demandam linguagens ou configurações específicas. Você pode criar actions da maneira que desejar e com as linguagens que preferir. E nesse artigo, entendemos o que é as Docker container actions, quando devemos utilizar e também como criar e testar em um GitHub Workflow.

## Referências

1. [Sobre ações personalizadas | GitHub Docs](https://docs.github.com/en/actions/creating-actions/about-custom-actions)
2. [Criando Docker container action | GitHub Docs](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action)
3. [Entendendo GitHub Actions | GitHub Docs](https://docs.github.com/pt/actions/learn-github-actions/understanding-github-actions)