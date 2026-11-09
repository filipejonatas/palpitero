# Plano de segurança: chaves e Firebase

Objetivo: fechar o alerta de secret scanning do GitHub e deixar o projeto Firebase protegido
antes de publicar o app. Projeto: `palpitero-620eb`.

**Regras de trabalho**
- Restrição de chave só com o app rodando, para testar o login logo depois de cada mudança.
- Nunca excluir chaves nem desativar as APIs que o Firebase usa: isso derruba o app.
- Marcar as caixas conforme for concluindo.

---

## Contexto (alerta de 2026-11-09)

- O GitHub acusou chaves `AIza…` do Google em `lib/firebase_options.dart`, gerado pelo
  `flutterfire configure` e publicado no commit `b566b91`.
- São 3 chaves criadas automaticamente pelo Firebase: `Browser key`, `Android key` e
  `iOS key (auto created by Firebase)`.
- **Não são senhas.** Elas só identificam o projeto e vão dentro do app de qualquer jeito
  (APK e JavaScript do site). Por isso o histórico do git **não** é reescrito e o arquivo
  continua versionado.
- O que protege os dados são as regras e o App Check:
  - `database.rules.json`: nega tudo por padrão; cada usuário só lê e grava o próprio nó;
    palpites e pontuação não aceitam gravação pelo cliente.
  - `storage.rules`: foto só do próprio usuário, até 5 MB, só imagem.
  - App Check: ativado em `lib/services/app_check_config.dart`, ainda sem modo obrigatório.

- As chaves já foram criadas com a restrição de API padrão do Firebase (veja a Fase 2), o
  que cobre o risco 1 abaixo. Falta a restrição por app (referenciador, pacote, bundle).

### Quando a chave vira problema
O histórico do git não aumenta o risco: a mesma chave vai estar no app publicado. O risco
depende do estado do projeto, não de onde a chave aparece:
1. **Chave sem restrição + API paga ativada no projeto** (ex.: Gemini/Generative Language).
   Qualquer pessoa usa a chave nessa API e o custo cai na conta. Vale também para uma API
   ativada **no futuro**, porque a chave sem restrição passa a valer nela.
2. **Regras de segurança afrouxadas** (ex.: `".read": true` para testar e esquecer).
3. **Abuso do Auth:** criação de contas em massa ou, se o login por SMS for ativado, envio
   de SMS pago.

## Fase 1: agora (não quebra o app, não precisa testar)

- [ ] Em [APIs ativadas](https://console.cloud.google.com/apis/dashboard?project=palpitero-620eb),
      desativar as APIs que não são do Firebase e o app não usa. Prioridade: Generative
      Language API (Gemini), se aparecer.
- [ ] Criar um alerta de orçamento no Billing (ex.: US$ 5) para avisar de uso inesperado.
- [ ] Regra fixa: nunca ativar uma API paga neste projeto sem antes restringir as chaves
      (Fase 2).

## Fase 2: quando o build rodar (precisa testar o login)

Em [Credenciais](https://console.cloud.google.com/apis/credentials?project=palpitero-620eb):

- [~] **Restrições de API** nas 3 chaves. Em 2026-11-09 vimos que pelo menos uma chave já
      vem com a restrição padrão do Firebase (lista de APIs do Firebase; Cloud Messaging
      desmarcado). Falta conferir nas 3 chaves: Generative Language e Vertex AI **desmarcados**;
      Identity Toolkit, Token Service, Firebase Realtime Database e Cloud Storage **marcados**.
      Não enxugar a lista sem testar o login.
- [ ] **Browser key:** referenciadores HTTP `https://palpitero-620eb.web.app/*`,
      `https://palpitero-620eb.firebaseapp.com/*` e `http://localhost:*`.
- [ ] **Android key:** pacote + SHA-1 do keystore de debug e de release.
- [ ] **iOS key:** bundle ID.
- [ ] Testar login e leitura de dados no web e no Android. Se quebrar: quase sempre falta
      uma API na lista ou um referenciador.
- [ ] Fechar o alerta no GitHub como "Won't fix": *"Chave pública do Firebase, restringida
      por API e por app."*

## Fase 3: antes de publicar

- [ ] Trocar `com.example.palpitero` por um ID definitivo (Android e iOS) e atualizar as
      restrições das chaves Android e iOS.
- [ ] App Check em **modo obrigatório** para o Realtime Database e o Storage, depois de ver nas
      métricas do App Check que as requisições chegam com token válido.
- [ ] Revisar `database.rules.json` e `storage.rules` (nada de leitura ou gravação abertas).
- [ ] Gerar o `google-services.json` no CI a partir de um secret (pendência do item 0.5 do
      [plano do design system](DESIGN_SYSTEM_PLAN.md)).

## Só se houver uso indevido: rotacionar as chaves

1. Criar uma chave nova em Credenciais, já com as restrições da Fase 2.
2. Associar a chave nova ao app no Firebase (campo `apiKeyId` do app na API de gerenciamento
   do Firebase; o console não tem esse campo).
3. Rodar `flutterfire configure` de novo e baixar outra vez o `google-services.json`.
4. Publicar o app com a chave nova e só então excluir a antiga.
