# TCC – Estruturação e boas práticas de APIs RESTful com Ruby on Rails

Repositório do Trabalho de Conclusão de Curso para obtenção do título de especialista em Engenharia de Software, desenvolvido por **Vitor Sant'Ana Navarro**.

O objetivo é comparar três protótipos de API Rails com níveis crescentes de sofisticação, medindo o impacto de autenticação JWT e cache Redis via testes de carga com Apache JMeter.

---

## Sumário

1. [Visão geral dos protótipos](#1-visão-geral-dos-protótipos)
2. [Pré-requisitos](#2-pré-requisitos)
3. [Instalação e configuração](#3-instalação-e-configuração)
4. [Rodando os protótipos](#4-rodando-os-protótipos)
5. [Testes automatizados (RSpec)](#5-testes-automatizados-rspec)
6. [Testes de carga (JMeter)](#6-testes-de-carga-jmeter)
7. [Análise dos resultados](#7-análise-dos-resultados)
8. [Endpoints de cada protótipo](#8-endpoints-de-cada-protótipo)
9. [Estrutura do repositório](#9-estrutura-do-repositório)

---

## 1. Visão geral dos protótipos

| Protótipo | Descrição | Porta | Autenticação | Cache |
|-----------|-----------|-------|--------------|-------|
| **P1 – Baseline** | API mínima sem autenticação | 3001 | Nenhuma | Nenhum |
| **P2 – Intermediate** | JWT + versionamento de API | 3002 | JWT (Bearer Token) | Nenhum |
| **P3 – Advanced** | JWT + Redis cache + Rate limiting | 3003 | JWT (Bearer Token) | Redis |

### Diferenças técnicas por protótipo

**Protótipo 1** — Rails API puro, sem autenticação. Serve como linha de base para medir o overhead das camadas seguintes.

**Protótipo 2** — Adiciona autenticação via JWT (`jwt` + `bcrypt`), endpoints versionados sob `/api/v1/`, documentação Swagger (`rswag`) e testes com RSpec.

**Protótipo 3** — Adiciona cache de respostas no Redis (5 minutos, invalidado em mutations) e rate limiting via `rack-attack` (300 req/5 min por IP; 100 req/min por token; 5 tentativas de login/min por IP).

---

## 2. Pré-requisitos

| Ferramenta | Versão mínima | Como verificar |
|------------|--------------|----------------|
| Ruby | 3.3.5 | `ruby -v` |
| Bundler | 2.x | `bundler -v` |
| PostgreSQL | 13+ | `psql --version` |
| Redis | 6+ | `redis-server --version` |
| Apache JMeter | 5.6+ | `jmeter --version` |
| Java | 11+ | `java -version` |
| Python | 3.8+ (opcional) | `python3 --version` |

> **Redis** só é necessário para o Protótipo 3.
> **JMeter/Java/Python** são necessários apenas para os testes de carga.

### Instalando o Ruby com rbenv

```bash
rbenv install 3.3.5
rbenv local 3.3.5   # ou global
```

### Instalando o JMeter (macOS/Linux)

```bash
# macOS
brew install jmeter

# Linux (manual)
wget https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz
tar -xzf apache-jmeter-5.6.3.tgz
export PATH="$PATH:$(pwd)/apache-jmeter-5.6.3/bin"
```

---

## 3. Instalação e configuração

Clone o repositório e configure cada protótipo individualmente.

```bash
git clone https://github.com/navarrovitor/rails-api-comparison.git
cd rails-api-comparison
```

### Protótipo 1

```bash
cd prototype-1-baseline
bundle install
rails db:create db:migrate db:seed
```

O seed cria **500 artigos** no banco.

### Protótipo 2

```bash
cd prototype-2-intermediate
bundle install
rails db:create db:migrate db:seed
```

O seed cria **500 artigos** e **1 usuário** de teste:

| Campo | Valor |
|-------|-------|
| email | `test@example.com` |
| senha | `password123` |

### Protótipo 3

```bash
cd prototype-3-advanced
bundle install
rails db:create db:migrate db:seed
```

Mesmo seed do P2. Certifique-se de que o Redis está rodando antes de iniciar o servidor:

```bash
redis-server --daemonize yes   # inicia em background
redis-cli ping                 # deve retornar PONG
```

---

## 4. Rodando os protótipos

Execute cada comando em um **terminal separado** a partir da raiz do monorepo:

```bash
# Terminal 1 – Protótipo 1
cd prototype-1-baseline && rails s -p 3001

# Terminal 2 – Protótipo 2
cd prototype-2-intermediate && rails s -p 3002

# Terminal 3 – Protótipo 3
cd prototype-3-advanced && rails s -p 3003
```

Verifique que cada servidor respondeu:

```bash
curl -s http://localhost:3001/articles | head -c 100
curl -s http://localhost:3002/up
curl -s http://localhost:3003/up
```

---

## 5. Testes automatizados (RSpec)

Os Protótipos 2 e 3 possuem suíte de testes com RSpec.

```bash
# Protótipo 2
cd prototype-2-intermediate
bundle exec rspec

# Protótipo 3
cd prototype-3-advanced
bundle exec rspec
```

Cobertura dos testes:

- `spec/models/` — validações de User e Article
- `spec/requests/api/v1/auth_spec.rb` — login, token inválido, credenciais erradas
- `spec/requests/api/v1/articles_spec.rb` — CRUD protegido por JWT
- `spec/requests/rate_limit_spec.rb` — (P3) throttle de login por IP
- `spec/integration/` — fluxos de ponta a ponta via rswag

### Documentação Swagger (P2 e P3)

Com o servidor rodando, acesse:

- P2: http://localhost:3002/api-docs
- P3: http://localhost:3003/api-docs

---

## 6. Testes de carga (JMeter)

### Cenários de carga

Cada plano `.jmx` contém **3 Thread Groups** executados em paralelo:

| Cenário | Threads | Ramp-up | Duração | Objetivo |
|---------|---------|---------|---------|----------|
| Carga Básica | 10 | 5s | 60s | Comportamento estável |
| Carga Crescente | 50 | 90s | 90s | Escalabilidade gradual |
| Pico de Requisições | 100 | 5s | 30s | Comportamento sob pico |

### Antes de cada execução

**Protótipo 3 — limpe o cache do Redis** para garantir resultados comparáveis:

```bash
redis-cli FLUSHALL
```

### Executando via linha de comando (recomendado)

Crie o diretório de resultados antes da primeira execução:

```bash
mkdir -p jmeter/results
```

```bash
# Protótipo 1 (servidor deve estar na porta 3001)
jmeter -n \
  -t jmeter/prototype-1-baseline.jmx \
  -l jmeter/results/prototype-1-results.csv \
  -e -o jmeter/results/p1-report/

# Protótipo 2 (servidor deve estar na porta 3002)
jmeter -n \
  -t jmeter/prototype-2-intermediate.jmx \
  -l jmeter/results/prototype-2-results.csv \
  -e -o jmeter/results/p2-report/

# Protótipo 3 (servidor deve estar na porta 3003 e Redis rodando)
redis-cli FLUSHALL
jmeter -n \
  -t jmeter/prototype-3-advanced.jmx \
  -l jmeter/results/prototype-3-results.csv \
  -e -o jmeter/results/p3-report/
```

> Para re-executar um plano, remova o diretório de relatório anterior ou use um nome diferente para `-o`, pois o JMeter exige que o diretório de saída esteja vazio.

### Executando via GUI (para debug)

```bash
jmeter
# File > Open > selecione o .jmx desejado
# Clique em ▶ para iniciar
```

### Ordem recomendada

Execute **um protótipo por vez**, com apenas o servidor correspondente ativo, para evitar interferência nos resultados:

1. P1 — linha de base, sem overhead de autenticação
2. P2 — observar o impacto do JWT (login a cada iteração)
3. P3 — comparar com P2 para medir o ganho do cache Redis

---

## 7. Análise dos resultados

Após rodar os três planos, use o script Python para comparar as métricas:

```bash
python3 jmeter/analyze_results.py
```

O script calcula para cada protótipo e cada cenário:

- Total de requisições
- Tempo médio de resposta (ms)
- Percentil 95 (ms)
- Throughput (req/s)
- Taxa de erro (%)

Os relatórios HTML gerados pelo JMeter (flag `-e`) ficam em `jmeter/results/p*/` e oferecem gráficos interativos de throughput, latência percentil (p50/p90/p95/p99) e taxa de erros.

---

## 8. Endpoints de cada protótipo

### Protótipo 1 — sem autenticação

```
GET    /articles        # Lista todos os artigos
GET    /articles/:id    # Exibe um artigo
POST   /articles        # Cria um artigo
GET    /up              # Health check
```

**Exemplo:**

```bash
curl http://localhost:3001/articles
curl http://localhost:3001/articles/1
curl -X POST http://localhost:3001/articles \
  -H "Content-Type: application/json" \
  -d '{"article": {"title": "Teste", "content": "Conteúdo"}}'
```

---

### Protótipos 2 e 3 — com JWT

**1. Obter token:**

```bash
curl -X POST http://localhost:3002/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
# Resposta: {"token": "<JWT>"}
```

**2. Usar o token nas requisições:**

```bash
TOKEN="<JWT obtido acima>"

# Listar artigos
curl http://localhost:3002/api/v1/articles \
  -H "Authorization: Bearer $TOKEN"

# Exibir artigo
curl http://localhost:3002/api/v1/articles/1 \
  -H "Authorization: Bearer $TOKEN"

# Criar artigo
curl -X POST http://localhost:3002/api/v1/articles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"article": {"title": "Novo", "content": "Corpo"}}'

# Atualizar artigo
curl -X PUT http://localhost:3002/api/v1/articles/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"article": {"title": "Atualizado"}}'

# Remover artigo
curl -X DELETE http://localhost:3002/api/v1/articles/1 \
  -H "Authorization: Bearer $TOKEN"
```

> Substitua a porta `3002` por `3003` para o Protótipo 3. Os endpoints são idênticos.

---

## 9. Estrutura do repositório

```
rails-api-comparison/
├── prototype-1-baseline/       # Rails API sem autenticação
│   ├── app/controllers/
│   │   └── articles_controller.rb
│   └── db/seeds.rb             # 500 artigos
│
├── prototype-2-intermediate/   # JWT + Swagger + RSpec
│   ├── app/controllers/api/v1/
│   │   ├── articles_controller.rb
│   │   └── auth_controller.rb
│   ├── spec/                   # Testes RSpec
│   └── swagger/                # Documentação gerada
│
├── prototype-3-advanced/       # JWT + Redis cache + Rack::Attack
│   ├── app/controllers/api/v1/
│   │   ├── articles_controller.rb  # Usa Rails.cache (Redis)
│   │   └── auth_controller.rb
│   ├── config/initializers/
│   │   └── rack_attack.rb      # Regras de rate limiting
│   └── spec/
│       └── requests/rate_limit_spec.rb
│
└── jmeter/
    ├── prototype-1-baseline.jmx
    ├── prototype-2-intermediate.jmx
    ├── prototype-3-advanced.jmx
    ├── analyze_results.py      # Script de comparação
    └── results/                # CSVs e relatórios HTML gerados
```

---

> Projeto de caráter acadêmico e experimental.
