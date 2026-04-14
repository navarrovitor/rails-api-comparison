# JMeter - Planos de Teste

Planos de carga para comparação de performance entre os três protótipos Rails.

## Pré-requisitos

- [Apache JMeter](https://jmeter.apache.org/download_jmeter.cgi) 5.6+ instalado
- Java 11+ disponível no PATH
- **Protótipo 3**: Redis rodando localmente na porta padrão (6379)
- Cada protótipo iniciado na porta correta antes de executar o plano correspondente

## Iniciando os Protótipos

Execute cada comando em um terminal separado a partir da raiz do monorepo:

```bash
# Protótipo 1 - Sem autenticação (porta 3001)
cd prototype-1-baseline && rails s -p 3001

# Protótipo 2 - JWT (porta 3002)
cd prototype-2-intermediate && rails s -p 3002

# Protótipo 3 - JWT + Cache Redis (porta 3003)
cd prototype-3-advanced && rails s -p 3003
```

## Limpeza do Cache (Protótipo 3)

> **Atenção:** Execute este comando antes de cada execução do Protótipo 3 para garantir
> resultados consistentes e comparáveis, sem dados de cache de execuções anteriores.

```bash
redis-cli FLUSHALL
```

## Estrutura dos Planos

Cada arquivo `.jmx` contém 3 Thread Groups executados em paralelo:

| Cenário | Threads | Ramp-up | Duração |
|---------|---------|---------|---------|
| Carga Básica | 10 | 5s | 60s |
| Carga Crescente | 50 | 90s | 90s |
| Pico de Requisições | 100 | 5s | 30s |

Os Thread Groups usam **scheduler com duration** (não loop count), garantindo
que o teste rode pelo tempo exato especificado independentemente da velocidade das respostas.

## Executando os Planos

### Via GUI (recomendado para desenvolvimento/debug)

```bash
# Abrir JMeter
jmeter

# Depois: File > Open > selecionar o .jmx desejado
# Clicar no botão Play (▶) para iniciar
```

### Via linha de comando (recomendado para CI/resultados limpos)

```bash
# Protótipo 1
jmeter -n -t jmeter/prototype-1-baseline.jmx -l jmeter/results/p1-run.jtl -e -o jmeter/results/p1-report/

# Protótipo 2
jmeter -n -t jmeter/prototype-2-intermediate.jmx -l jmeter/results/p2-run.jtl -e -o jmeter/results/p2-report/

# Protótipo 3
jmeter -n -t jmeter/prototype-3-advanced.jmx -l jmeter/results/p3-run.jtl -e -o jmeter/results/p3-report/
```

Flags utilizadas:
- `-n` — modo não-GUI (headless)
- `-t` — caminho do plano de teste
- `-l` — arquivo de log de resultados brutos (`.jtl`)
- `-e` — gera relatório HTML ao final
- `-o` — diretório de saída do relatório HTML (deve estar vazio ou não existir)

## Ordem Recomendada de Execução

1. **Protótipo 1** — linha base, sem overhead de autenticação
2. **Protótipo 2** — introduz JWT; observe o impacto do login por iteração
3. **Protótipo 3** — adiciona cache; compare com P2 para medir o ganho do Redis

Execute um protótipo por vez com a aplicação correspondente rodando para evitar
interferência entre os resultados.

## Resultados

Os CSVs são salvos automaticamente em `jmeter/results/` durante a execução:

```
jmeter/results/
  prototype-1-results.csv
  prototype-2-results.csv
  prototype-3-results.csv
```

Campos capturados: `timeStamp`, `elapsed`, `label`, `responseCode`, `success`,
`bytes`, `sentBytes`, `Latency`, `Connect`.

Os relatórios HTML gerados pela flag `-e` oferecem gráficos de throughput,
latência percentil (p50/p90/p95/p99) e taxa de erros para cada cenário.
