# Entendendo e Criando Docker Container Actions

As actions são tasks individuais que podem ser combinadas para criar jobs e customizar seus workflows, ajudando a diminuir a quantidade repetitiva de código. Você pode tanto utilizar as actions disponibilizadas no Github Marketplace ou customizar suas próprias actions.

O github Actions disponibiliza 3 tipos de actions customizadas: Javascript, Composite e Docker container. Nesse artigo vamos entender sobre Docker Container Actions, como implementar sua primeira docker container action e testá-la em um github workflow.

## Docker Container Action

Docker Container permite que você crie actions customizadas empacotando o ambiente com o código do Github Actions. Dessa forma, quem consumir sua action não precisa se preocupar com as dependências necessárias para executá-la, basta referenciar a action em seu workflow e executar, pois ela já conterá todos os componentes necessários para execução.

### Quando usar Docker container action?

Docker container action é a opção ideal para actions que precisam ser executadas em ambientes com configurações específicas, já que permite personalizar o sistema operacional, as ferramentas, código e dependências sem necessitar adicionar ao runner, basta apenas o runner possuir o Docker e é possível executar no mesmo runner diversas docker actions e cada uma com sua personalização.
Você também pode utilizar docker container quando Javascript actions não for uma opção, seja por querer utilizar uma versão específica do Node, já que as Javascript actions utilizam Node(12) ou por familiaridade com outras linguagens e querer manter a consistência utilizando a mesma linguagem de suas outras ferramentas, já que com o docker container é possível construir actions utilizando suas linguagens favoritas, seja Python, Go, bash, ruby e entre outras.

## Criando Docker Container Actions

Agora vamos entender e executar os passos necessários para criar um docker container, e teremos então uma docker container action desenvolvida em python que chama a API do github para listar branches de um repositório público.

### Pré requisitos

**Linux SO e Docker:** Para rodar Docker container actions, os Self-hosted runners precisam utilizar o sistema operacional Linux e ter o Docker instalado, mas você pode utilizar os Github-hosted runners, que são gerenciados pelo github e já possuem o docker instalado, como por exemplo “ubuntu-latest”.

**Repositório:** Precisamos ter um repositório do github. Estarei utilizando “list-branches-action” como nome do repositório, mas você pode criar com o nome que preferir. Para informações de criação de repositórios, veja: Como criar repositórios.

**Clonar repositório:** após criar o repositório, clone em sua máquina. Saiba mais em: Clonando um repositório

**Mudar diretório:** em seu terminal, mude o diretório para o novo repositório. Execute o comando:

```powershell
cd list-branches-action
```

### Implementando código da action

No diretório raiz “list-branch-action”, vamos criar o arquivo main.py que conterá o código que a action irá executar:

```python
# Código da action
import requests
import json
import sys

r=requests.get("https://api.github.com/repos/"+sys.argv[1]+"/"+sys.argv[2]+"/branches", headers={"Accept": "application/vnd.github+json" ,"X-GitHub-Api-Version":"2022-11-28"})

objeto = json.loads(r.text)

print("\nLista de branchs do repositório "+sys.argv[2]+ " :")
for v in objeto:
    print(v['name'])
```

Esse script faz uma chamada a API do Github `https://api.github.com/repos/OWNER/REPO/branches` que recebe dois parâmetros: `OWNER`, que representa o owner do repositório e `REPO`, que representa o nome do repositório do qual iremos listar as branches.

Para fazer essa chamada, inicialmente importamos as bibliotecas necessárias. Sendo requests, que possibilita realizarmos requests http, json para trabalharmos com os dados JSON e sys para manipularmos os parâmetros que são passados na execução do programa.

Na linha 4 onde fazemos a request, substituímos os argumentos `OWNER` e `REPO` por `sys.argv[1]` e `sys.argv[2]` correspondente, pois esses parâmetros serão atualizados com os valores que serão passados como argumento para o container.

E então na linha 6 convertemos o json da resposta da API em um objeto python Dictionary, para então na linha 12 conseguirmos percorrer esse dictionary e trazer apenas o nome das branches.

### Criando o Dockerfile

Com o código da action definido, seguindo a sintaxe e os padrões descritos em Dockerfile support for GitHub Actions criamos o arquivo Dockerfile que será utilizado para criar a imagem que conterá o código da action.

```dockerfile
# Imagem do Container que executa o código da action
FROM python:3.8-alpine

RUN pip install requests

COPY main.py /main.py

ENTRYPOINT ["python", "/main.py"]
```

Estamos utilizando `python:3.8-alpine` como base para nossa imagem, pois já inclui o python. Instalamos as bibliotecas necessárias para execução da action que são importadas no arquivo `main.py` e ao final do arquivo adicionamos uma instrução para que o Docker execute o arquivo `main.py` assim que iniciar o container.

### Criando arquivo action.yml

No diretório “list-branches-action”, criamos um arquivo `action.yml` que contém toda a definição da action, como descrição, inputs e outputs.

```yml
# action.yml
name: 'List Branchs Action'
description: 'Lista branchs de um repositório público'
inputs:
  owner: # id do input
    description: 'sua organização ou usuário github'
    required: true
  repos: # id do input
    description: 'nome do repositório' # que possui as branchs a serem listadas
    required: true
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.owner }}
    - ${{ inputs.repo }} 
```

No action.yml acima, setamos o nome, descrição da action e também o ícone e a cor que representará a action caso deseje publicar no Github Marketplace.

#### Passando Inputs para o container

Para passar os argumentos para o docker container, precisamos declarar os inputs e então passá-los como argumento usando args. No nosso action.yml, temos os inputs obrigatórios ``owner`` e ``repo`` que são passados  como argumentos ``inputs.owner``  e ``inputs.repos`` que serão então utilizados para atualizar os parâmetros ``sys.args[1]`` e ``sys.argv[2]`` definidos no nosso arquivo ``main.py``.

```yml
inputs:
  owner: # id do input
    description: 'sua organização ou usuário github'
    required: true
  repos: # id do input
    description: 'nome do repositório' # que possui as branchs a serem listadas
    required: true
```

```yml
runs:
  args:
    - ${{ inputs.owner }}
    - ${{ inputs.repo }} 
```

#### Definindo a imagem da action

Precisamos especificar a imagem que será utilizada para iniciar o container que contém o código da action. Na sessão run passamos a propriedade using como docker e podemos definir a imagem de 2 maneiras:

1. Usando o arquivo Dockerfile presente no repositório da action:

    ```yml
    runs:
      using: 'docker'
      image: 'Dockerfile'
    ```

    Assim como em nosso exemplo, quando passamos o Dockerfile, o Github runner construirá  uma imagem a partir desse Dockerfile e iniciará um container que utiliza essa imagem, que executará o código definido em main.py.

    > As Docker actions costumam ser mais lentas que JavaScript actions, pois o runner precisa realizar o build dessa imagem.

2. Usando uma imagem de um  Docker registry:

    ```yml
    runs: 
      using: 'docker'
      image: 'docker://ubuntu:20.04
    ```

    Ao utilizar uma imagem de um docker registry, o Github runner não precisa construí-la e apenas realiza o pull dessa imagem, buscando ela e executando-a para inciar o container contendo o código da action.

### Adicionando tag e realizando push da action para o repositório do github

Após a criação dos arquivos, main.py, Dockerfile e action.yml, podemos fazer o commit, realizar o push para nosso repositório do github e adicionar uma annotated tag, que será utilizada posteriormente para identificar a versão da nossa action. No diretório local “list-branch-action”, execute:

```bash
git add .

git commit -m “my actions file”

git tag -a v1 -m " first version list branch tag"

git push -–follow-tags
```

### Testando a Docker container action em um GitHub Workflow

Com a action disponível em nosso repositório, já podemos testá-la em um github workflow. As actions públicas podem ser utilizadas em qualquer repositório, mas podemos ter actions em repositório privado onde podemos controlar o acesso e também podemos publicá-las no Github Marketplace.

Para usarmos a action, precisamos ter um arquivo .yml no diretório github/workflows, então nesse diretório criamos o arquivo main.yml, que é executado sempre que for realizado um push na branch master do repositório.

```yml
on: [push]

jobs:
  List-Branches:
    runs-on: ubuntu-latest
    name: Job para listar Branches de repositório GitHub
    steps:
      - name: Listar Branches action step
        id: list
        uses: geovanams/list-branchs-action@main
        with:
          owner: 'geovanams'
          repos: 'list-branchs-action'
```

Esse workflow possui um único job chamado “List-Branchs” que executará o step “List Branches action step”. Nesse step chamamos a action que criamos anteriormente definindo em “uses”. 

Como a actions está em um repositório público estamos definindo a action usando a seguinte sintaxe: geovanams/list-docker-action@v1, onde temos o nome do owner ou organização, em seguida o nome do repositório e então @v1 representando a versão da action, que estamos utilizando uma tag, mas podemos versionar usando commit ID ou até mesmo o nome da branch. Para mais informações sobre como gerenciar versão de actions com tags e releases, visite: https://docs.github.com/en/actions/creating-actions/about-custom-actions#good-practices-for-release-management

E para passarmos os parâmetros da action, utilizamos o atributo “with”. Nesse workflow, passamos os parâmetros owner e repos que você pode substituir os valores pelo owner e nome do repositório do qual deseja listar as branchs.

```yml
uses: geovanams/actionteste@master
with:
    owner: 'geovanams'
    repos: 'List-Branch-Docker-Action'
```

Após salvar o arquivo no repositório, o github já iniciará o workflow. Na aba Actions, podemos ver os logs de execução dos jobs e steps do workflow.

[image]

Note que temos 2 steps principais:

**Build geovanams/actionteste@master:** que ao definirmos que nossa action utilizaria a imagem a partir do dockerfile, o github adicionou esse step para realizar o build da imagem que será utilizado no step sequinte. Se ao invés do Dockerfile passessmos uma imagem de um registry Docker, o github iria adicionar uma step de pull no lugar de uma de build.

**List Branch action step:** Esse é o step que de fato chamamos a docker action, que mostra os parâmetros passados para action e o resultado de sua execução, listando então todas as branchs do repositório definido.

[image]

### Estrutra de arquivos do repositório

Então ao seguir os passos anteriores, terememos então um repositório estruturado da seguinte forma:

```bash
.
├── .github/workflows
│   └── main.yml
├── Dockerfile
├── README.md
├── action.yml
└── main.py
```

## Conclusões

As docker github actions é uma ótima escolha para criação de actions customizadas que demandam linguagens ou configurações específicas. Você pode criar actions da maneira que desejar e com as linguagens que preferir. E nesse artigo entendemos oque é as docker container actions, quando devemos utilizar e também como criar e testar em um github Workflow.