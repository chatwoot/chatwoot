# Funcionalidade: Clique no Cabeçalho para Abrir/Fechar Perfil do Contato

## 📋 Descrição

Esta funcionalidade permite que o usuário clique na área do cabeçalho da conversa (avatar + nome do contato) para abrir ou fechar o painel lateral com as informações detalhadas do contato. Implementa um comportamento de toggle (alternância) - se o painel estiver fechado, abre; se estiver aberto, fecha.

## 🎯 Objetivo

Melhorar a experiência do usuário ao tornar mais intuitivo o acesso às informações do contato, permitindo que o usuário clique diretamente na área identificadora do contato no cabeçalho da conversa, ao invés de precisar usar apenas o botão de alternância lateral.

## 📁 Arquivos Modificados

### `app/javascript/dashboard/components/widgets/conversation/ConversationHeader.vue`

Este é o componente que renderiza o cabeçalho da conversa, incluindo o avatar, nome do contato e informações adicionais (como inbox e status de snooze).

## 🔧 Implementação Técnica

### 1. Importações Adicionadas

```javascript
import { useUISettings } from 'dashboard/composables/useUISettings';
```

Foi necessário importar o composable `useUISettings` para:
- Acessar o estado atual do painel lateral (`uiSettings`)
- Atualizar as configurações de UI (`updateUISettings`)

### 2. Acesso ao Estado do Painel

```javascript
const { updateUISettings, uiSettings } = useUISettings();
```

Adicionado `uiSettings` ao destructuring para poder verificar o estado atual do painel (`is_contact_sidebar_open`).

### 3. Função de Toggle

```javascript
const toggleContactPanel = () => {
  const isCurrentlyOpen = uiSettings.value?.is_contact_sidebar_open || false;
  updateUISettings({
    is_contact_sidebar_open: !isCurrentlyOpen,
    is_copilot_panel_open: false,
  });
};
```

**Funcionamento:**
- Verifica o estado atual do painel através de `uiSettings.value?.is_contact_sidebar_open`
- Se o painel estiver aberto (`true`), fecha (`false`)
- Se o painel estiver fechado (`false`), abre (`true`)
- Garante que o painel do Copilot seja fechado quando o painel de contato for aberto

### 4. Área Clicável no Template

```vue
<div
  class="flex items-center cursor-pointer"
  role="button"
  tabindex="0"
  @click="toggleContactPanel"
>
  <Avatar ... />
  <div class="flex flex-col items-start ...">
    <!-- Nome e informações do contato -->
  </div>
</div>
```

**Alterações no template:**
- Adicionada a classe `cursor-pointer` para indicar visualmente que a área é clicável
- Adicionado `role="button"` para acessibilidade
- Adicionado `tabindex="0"` para permitir navegação por teclado
- Adicionado `@click="toggleContactPanel"` para executar a função ao clicar

**Nota:** A área clicável envolve apenas o avatar e as informações do contato, mantendo o botão "Voltar" (`BackButton`) fora dessa área para preservar sua funcionalidade original.

## 🔄 Fluxo de Funcionamento

1. **Usuário clica na área do avatar + nome do contato**
2. **Sistema verifica o estado atual do painel lateral**
   - Se `is_contact_sidebar_open === false` → Abre o painel (`true`)
   - Se `is_contact_sidebar_open === true` → Fecha o painel (`false`)
3. **O componente `ConversationSidebar` reage à mudança de estado**
   - Quando `is_contact_sidebar_open === true`, renderiza o `ContactPanel`
   - Quando `is_contact_sidebar_open === false`, oculta o painel
4. **O painel exibe as informações do contato** através do componente `ContactPanel`

## 🎨 Componentes Relacionados

### `ConversationSidebar.vue`
Componente que gerencia a exibição do painel lateral baseado no estado `is_contact_sidebar_open`.

### `ContactPanel.vue`
Componente que exibe as informações detalhadas do contato, incluindo:
- Informações básicas do contato
- Ações da conversa
- Participantes
- Informações da conversa
- Atributos customizados
- Conversas anteriores
- Macros
- Notas do contato
- Integrações (Shopify, Linear, etc.)

### `SidepanelSwitch.vue`
Componente que já possuía a funcionalidade de toggle do painel lateral. A nova implementação reutiliza a mesma lógica de estado, mantendo consistência na aplicação.

## ✅ Benefícios

1. **Melhor UX**: Acesso mais intuitivo às informações do contato
2. **Consistência**: Reutiliza o mesmo sistema de estado já existente
3. **Acessibilidade**: Inclui atributos ARIA (`role="button"`) e suporte a teclado (`tabindex`)
4. **Feedback Visual**: Cursor pointer indica que a área é clicável
5. **Não Invasivo**: Não interfere com outras funcionalidades existentes (como o botão Voltar)

## 🧪 Como Testar

1. **Abrir uma conversa** no Chatwoot
2. **Verificar que o painel lateral está fechado** inicialmente
3. **Clicar na área do avatar + nome do contato** no cabeçalho
4. **Verificar que o painel lateral abre** mostrando as informações do contato
5. **Clicar novamente na mesma área**
6. **Verificar que o painel lateral fecha**

### Testes Adicionais

- Verificar que o botão "Voltar" continua funcionando normalmente
- Verificar que o botão de toggle lateral (`SidepanelSwitch`) também funciona e está sincronizado
- Verificar que ao abrir o painel pelo cabeçalho, o painel do Copilot fecha (se estiver aberto)
- Verificar acessibilidade: navegar até a área usando Tab e ativar com Enter

## 📝 Notas Técnicas

- A implementação utiliza o padrão de **Composition API** do Vue 3 (`<script setup>`)
- O estado é gerenciado através do **Vuex store** via `useUISettings` composable
- A funcionalidade é **reativa** - mudanças no estado são refletidas automaticamente na UI
- O código segue os padrões do projeto Chatwoot, utilizando Tailwind CSS para estilização

## 🔗 Referências

- Componente modificado: `app/javascript/dashboard/components/widgets/conversation/ConversationHeader.vue`
- Composable utilizado: `dashboard/composables/useUISettings`
- Componente relacionado: `app/javascript/dashboard/components/widgets/conversation/ConversationSidebar.vue`
- Componente relacionado: `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`

