# PCS3225
Repositório para os Exercícios Programa de Sistemas Digitais 2

## Organização do repositório

Cada EP proposto está dentro da sua respectiva pasta.

Os arquivos que descrevem componentes devem ficar dentro da pasta `component`.

Os testbenches de cada componente devem ficar dentro da pasta `testbench` e deverão ser nomeados `<component>_tb`. Além disso, a entidade deve seguir o mesmo padrão de nomenclatura para evitar erros no Makefile.

Por fim, na pasta de cada EP há um arquivo `description.mk`. Ele deve conter uma lista com os arquivos da pasta `components` em ordem de prioridade (caso haja dependência entre eles), e uma variável para identificar o componente padrão que será usado nos testes. Um exemplo mais completo pode ser visto no [EP1](EP1/description.mk).

```Makefile
# Name of all components in priority order
CPNT_LIST := multiplicador_fd multiplicador_uc multiplicador

# Name of the component to be tested
CPNT ?= multiplicador

# Commands to prepare test files
PREPARE_TEST :=
```

## Compilando e executando

Para compilar, é necessário ter instalado o [GHDL](https://github.com/ghdl/ghdl) e adicioná-lo ao PATH da shell utilizada.

Todos os comandos listados abaixo serão executados para um EP específico, identificado pela variável `EP` do Makefile. Para mudar o projeto em que os comandos serão executados, basta mudar o valor padrão da variável para o nome da pasta do projeto atual. Também é possível fazer isso na chamada do comando, adicionando o novo valor da variável. Para executar o comando `make` no EP1, seria preciso fazer

```bash
make EP=EP1
```

### Analisar
Para analisar os componentes e testbenches, execute o comando
```bash
make analyse
```
ou apenas
```bash
make
```

### Verificar sintaxe
Para apenas a sintaxe dos arquivos, execute
```bash
make check_syntax
```

### Limpar
Para limpar os arquivos gerados durante a compilação, execute
```bash
make clean
```

### Testar
Para testar, execute o comando
```bash
make test
```
Nesse caso, o componente que será testado é aquele com o nome salvo na variável `CPNT` de `description.mk` (alu no EP0), assim, é possível mudar o componente padrão direto no arquivo de descrição do projeto (editando o valor inicial da variável), ou na linha de comando.

Além disso, para ver o resultado da simulação em um ambiente gráfico, utiliza-se a variável VISUAL=1. Note que para utilizar esse recurso, é preciso ter o GtkWave instalado no sistema.

Assim, para indicar precisamente qual o projeto utilizado, qual componente deverá ser testado e se o ambiente gráfico deve ou não ser aberto, é preciso executar

```bash
make test EP=EP1 CPNT=multiplicador VISUAL=1
```
O componente `multiplicador` será testado com a testbench `multiplicador_tb` e o GtkWave será aberto para visualizar o resultado da simulação.

OBS: Para testar o CPNT=multiplicador, é necessário executar o arquivo multiplicador_tb, por isso o padrão de nomenclatura deve sempre ser seguido.

OBS2: É necessário analisar os componentes antes de testar, e após qualquer mudança também.

## Instalando o necessário

### GHDL

Em breve

### GtkWave

Para instalar o GtkWave, basta executar os seguintes comandos.

```bash
sudo apt update
sudo apt install gtkwave
```
