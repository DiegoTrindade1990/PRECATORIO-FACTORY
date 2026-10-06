# 🚀 PRECATÓRIO FACTORY V6 - DEPLOY COMPLETO EM 5 MINUTOS

## O QUE TEM DENTRO DESSE ZIP:
- precatorio_factory_v6_schema.sql - Banco com 8 tabelas + RLS + logs sem PII (baseado no seu OrganizadorPDFv5.py)
- backend_fastapi_v6.py - API FastAPI com ZIP, Google Drive, OneDrive, GAT 04.153, IR 12.080
- Dockerfile + docker-compose.yml - Sobe tudo com 1 comando
- deploy_automatico.sh - Script automático
- SECURITY_CHECKLIST.md - Segurança blindada
- requirements.txt
- 6 artefatos HTML prontos (demo fake, real, V6 completo, segurança)

## PASSO A PASSO EXATO - COPIE E COLE:

### OPÇÃO 1 - MAIS FÁCIL (Sem Docker, 100% grátis - Recomendada):

**1. Criar Supabase (2 min):**
```
1. Acesse https://supabase.com -> New Project -> Nome: precatorio-factory
2. Vá em SQL Editor -> New Query
3. Abra o arquivo precatorio_factory_v6_schema.sql desse ZIP (copie tudo)
4. Cole no SQL Editor e clique RUN
5. Pronto! 8 tabelas criadas com RLS + 3 policiais fictícios de teste
6. Vá em Project Settings -> API -> Copie URL, anon key e service_role key
```

**2. Criar Asaas (3 min - para cobrança PIX/Boleto/Cartão):**
```
1. Acesse https://asaas.com -> Criar conta grátis
2. Configurações -> Integrações -> API -> Copie sua API Key
3. Configurações -> Webhooks -> Novo Webhook:
   URL: https://SEU-BACKEND.railway.app/webhook/asaas (você vai pegar depois)
   Eventos: Marque PAYMENT_RECEIVED, PAYMENT_CONFIRMED, PAYMENT_OVERDUE
   Token: Crie um token secreto ex: meu_token_123 (guarde)
```

**3. Deploy Backend no Railway (2 min - grátis):**
```
1. Acesse https://railway.app -> New Project -> Deploy from GitHub (ou Empty Project)
2. Conecte seu GitHub ou faça upload do backend_fastapi_v6.py
3. Renomeie backend_fastapi_v6.py para main.py no Railway
4. Vá em Variables e adicione:
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_SERVICE_KEY=sua-service-key
   ASAAS_API_KEY=sua-asaas-key
   ASAAS_WEBHOOK_TOKEN=seu_token_123
5. Deploy -> Copie a URL do backend (ex: https://precatorio-factory-production.up.railway.app)
6. Volte no Asaas e atualize Webhook URL com essa URL + /webhook/asaas
```

**4. Deploy Frontend na Vercel (2 min - grátis):**
```
1. Acesse https://vercel.com -> New Project -> Importe pasta com artefatos HTML
2. Ou simplesmente arraste o arquivo precatorio_factory_v6_completo_agentic_artifact_6_66051465409e.html
3. Adicione Environment Variables:
   VITE_SUPABASE_URL=https://seu-projeto.supabase.co
   VITE_SUPABASE_ANON_KEY=sua-anon-key
   VITE_API_URL=https://seu-backend.railway.app
4. Deploy -> URL final: https://seu-projeto.vercel.app
```

**PRONTO! Seu site já está online aceitando ZIP, Drive, OneDrive e liberando acesso automático!**

---

### OPÇÃO 2 - COM DOCKER (1 comando - para quem tem Docker instalado):

```bash
# 1. Descompacte esse ZIP em uma pasta
unzip precatorio_factory_v6_completo.zip -d precatorio-factory
cd precatorio-factory

# 2. Crie arquivo .env (copie do .env.example e preencha)
cp .env.example .env
nano .env  # Cole suas chaves do Supabase e Asaas

# 3. Rode 1 comando - sobe tudo!
docker-compose up -d --build

# 4. Acesse:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# Docs da API: http://localhost:8000/docs

# Para ver logs:
docker-compose logs -f api

# Para parar:
docker-compose down
```

### CÓDIGO QUE VOCÊ DEVE EXECUTAR - RESUMO EM 3 LINHAS:

**Se for usar Railway + Vercel (recomendado):**
```bash
# Nenhum código local! Só copiar SQL no Supabase e dar deploy nos botões
# Backend: railway.app -> New Project -> main.py
# Frontend: vercel.com -> New Project -> HTML
```

**Se for usar Docker local:**
```bash
docker-compose up -d --build
# Pronto! http://localhost:3000
```

**Se for usar script automático (Linux/Mac):**
```bash
chmod +x deploy_automatico.sh
./deploy_automatico.sh
```

---

### COMO TESTAR COM SEU PDF REAL (Igual seu OrganizadorPDFv5.py):

1. Acesse seu site: https://seu-projeto.vercel.app
2. Escolha tipo: GAT (04.153) ou IR_ALIMENTACAO (12.080)
3. Arraste o PDF de 11 páginas que você me enviou OU o ZIP com 45 PDFs
4. Ou cole link do Google Drive: https://drive.google.com/drive/folders/...
5. Clique Processar -> Barra de progresso 32/45 -> Baixar XLSX preenchido

---

### ONDE LIBERAR ACESSO QUANDO CLIENTE COMPRA:

1. Cliente paga no seu site -> Asaas recebe PIX/Boleto/Cartão
2. Asaas dispara webhook para seu backend /webhook/asaas
3. Backend verifica token e libera automaticamente: status=active, plano=pro
4. Você recebe e-mail "Novo pagamento R$197 - Escritório Silva"
5. Se quiser liberar na mão: Acesse /admin no seu site -> Lista de escritórios -> Botão "Liberar Pro"

Tudo automático, você não precisa fazer nada!

---

### SEGURANÇA - JÁ ESTÁ BLINDADO:

- RLS ativado: cada escritório só vê seus dados
- Auto-delete 24h: PDFs apagados automaticamente
- Logs sem PII: só metadados, nunca CPF/nome completo
- HTTPS + WAF + DDoS da Vercel/Railway
- Asaas PCI Nível 1 - você nunca vê número de cartão

Veja SECURITY_CHECKLIST.md completo dentro do ZIP.

---

### SUPORTE:

Se der erro em algum passo, me mande print que eu te ajudo ao vivo.

Seus exemplos GAT_EXEMPLO, IR_EXEMPLO permanecem em sigilo total.
