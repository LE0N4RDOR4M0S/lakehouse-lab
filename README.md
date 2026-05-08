# Data Lakehouse Local - PoC

Repositório contendo a infraestrutura as code (IaC) e pipelines de processamento para um Data Lakehouse 100% open-source, rodando localmente via containers. O ambiente foi desenhado para suportar alta volumetria e consultas analíticas de baixa latência em dados governamentais.

## Infraestrutura e Stack Tecnológico

A stack opera de forma desacoplada, separando armazenamento, catálogo e processamento:

* **Armazenamento (Storage):** MinIO. Atua como o Data Lake (compatível com API S3). Todo o dado físico mora aqui.
* **Formato de Tabela:** Apache Iceberg. Traz transações ACID, time travel e evolução de schema para o S3.
* **Catálogo de Metadados:** Hive Metastore (versão Standalone) apoiado por um banco MariaDB. Ele mapeia os ponteiros do Iceberg para que as engines saibam onde os dados estão.
* **Processamento (Engine de ETL):** PySpark 3.5. Responsável pelo processamento distribuído, rodando os scripts de ingestão e transformação.
* **Consulta Analítica (Query Engine):** Trino. Conecta no Hive Metastore, lê os metadados, vai ao MinIO e entrega os dados via SQL ANSI em milissegundos.

**Subindo a infra:**

```bash
docker compose up -d
```

## Arquitetura Medalhão

O fluxo de dados segue o padrão Medallion Architecture para isolar a sujeira da origem e garantir um modelo analítico confiável na ponta:

* ** Camada Bronze:** Ingestão *raw*. O dado é baixado das fontes abertas (arquivos CSV/ZIP) e gravado no Iceberg exatamente como veio, recebendo apenas um carimbo de `data_ingestao` para rastreabilidade.
* ** Camada Prata:** Higienização. Drop de nulos críticos, padronização de strings, uso intensivo de Regex para limpar máscaras de CNPJ/CPF e conversão de valores monetários para *float*.
* ** Camada Ouro:** Regras de negócio e modelagem. JOINs entre tabelas fato e dimensão, agregações e criação de *flags* de auditoria. O dado fica pronto para ser consumido pelo Trino via DBeaver.

## Objetivo Prático (Prova de Conceito)

A pipeline implementada valida a arquitetura cruzando duas bases massivas do Portal da Transparência:

1. **CEIS (Cadastro de Empresas Inidôneas e Suspensas):** Empresas proibidas de licitar/contratar com a administração pública.
2. **Pagamentos a Favorecidos (CGU):** Histórico de pagamentos efetuados pelo governo.

**A lógica aplicada:**
Os scripts processam a base de pagamentos (Prata) e executam um `INNER JOIN` com o CEIS (Prata) usando o CNPJ higienizado como chave, gerando uma tabela (Ouro) que aponta CNPJs sancionados que constam na lista de recebimentos.

**Aviso Importante:**
Este repositório é um laboratório de **Engenharia de Dados**. Os dados gerados na camada Ouro são puros, extraídos diretamente de fontes abertas e cruzados de forma estritamente programática (SQL/PySpark). **Não há qualquer interpretação de mérito, juízo de valor, validação de exceções contratuais ou análise legal sobre os resultados.** O objetivo do cruzamento é exclusivamente validar o funcionamento, a escalabilidade e o acoplamento da infraestrutura do Data Lakehouse.
