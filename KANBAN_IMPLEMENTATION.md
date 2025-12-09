# Documentação da Implementação do Kanban de Contatos

## Resumo Executivo

Este documento descreve a implementação do recurso de Kanban de Contatos no Chatwoot. **O que está funcionando atualmente é a criação da página e a exibição básica dos contatos**. As funcionalidades de drag-and-drop, menus de opções e outras interações ainda precisam de refinamento e testes.

---

## ✅ Funcionalidades Implementadas e Funcionando

### 1. Estrutura da Página Kanban

#### 1.1 Criação da Rota e Navegação
- ✅ Adicionada aba "Kanban" na página de Contatos
- ✅ Integração com o sistema de rotas existente
- ✅ TabBar para alternar entre "Lista" e "Kanban"
- ✅ Persistência da view selecionada via query params

**Arquivos:**
- `app/javascript/dashboard/routes/dashboard/contacts/pages/ContactsIndex.vue`

#### 1.2 Componente Principal
- ✅ Componente `KanbanView.vue` criado e renderizando
- ✅ Layout responsivo com sidebar e área principal
- ✅ Header com seleção de funil e botões de ação

**Arquivos:**
- `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanView.vue`

### 2. Exibição de Contatos

#### 2.1 Sidebar de Contatos
- ✅ Lista de contatos exibida na sidebar esquerda
- ✅ Filtragem de contatos que já estão no funil
- ✅ Exibição de avatar, nome e email dos contatos
- ✅ Estados de loading e empty state

**Arquivos:**
- `app/javascript/dashboard/components-next/Contacts/Kanban/ContactsSidebar.vue`

#### 2.2 Colunas do Kanban
- ✅ Colunas renderizadas com base nas configurações do funil
- ✅ Cabeçalhos das colunas com nome e badge "FIXA" quando aplicável
- ✅ Exibição de "R$ 0,00" e "Nenhum contato" quando vazio
- ✅ Layout visual consistente

**Arquivos:**
- `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanColumn.vue`

#### 2.3 Cards de Contato
- ✅ Cards de contato exibidos nas colunas
- ✅ Informações do contato (avatar, nome, data de última atividade)
- ✅ Visual consistente com o design system

**Arquivos:**
- `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanCard.vue`

### 3. Backend - Estrutura de Dados

#### 3.1 Modelos e Migrações
- ✅ Tabela `funnels` criada com campos necessários
- ✅ Tabela `funnel_contacts` (join table) criada
- ✅ Modelos `Funnel` e `FunnelContact` implementados
- ✅ Associações configuradas (Account, Team, Contact)
- ✅ Validações básicas implementadas

**Arquivos:**
- `db/migrate/20250115000000_create_funnels.rb`
- `db/migrate/20250115000001_create_funnel_contacts.rb`
- `app/models/funnel.rb`
- `app/models/funnel_contact.rb`

#### 3.2 API REST
- ✅ Endpoints para CRUD de funnels
- ✅ Endpoints para gerenciar contatos nos funis
- ✅ Endpoint `move_contact` para drag-and-drop
- ✅ Jbuilder views para serialização JSON

**Arquivos:**
- `app/controllers/api/v1/accounts/funnels_controller.rb`
- `app/controllers/api/v1/accounts/funnels/funnel_contacts_controller.rb`
- `app/views/api/v1/models/_funnel.json.jbuilder`
- `app/views/api/v1/accounts/funnels/index.json.jbuilder`
- `app/views/api/v1/accounts/funnels/funnel_contacts/index.json.jbuilder`

#### 3.3 Autorização
- ✅ Políticas Pundit para `Funnel` e `FunnelContact`
- ✅ Controle de acesso baseado em roles (admin/agent)

**Arquivos:**
- `app/policies/funnel_policy.rb`
- `app/policies/funnel_contact_policy.rb`

### 4. Estado e Gerenciamento de Dados

#### 4.1 Vuex Store
- ✅ Módulo `funnels` criado no Vuex
- ✅ Actions para buscar, criar, atualizar e deletar funnels
- ✅ Actions para gerenciar contatos nos funis
- ✅ Getters para acessar dados dos funis
- ✅ Mutations para atualizar o estado

**Arquivos:**
- `app/javascript/dashboard/store/modules/funnels/index.js`
- `app/javascript/dashboard/store/modules/funnels/actions.js`
- `app/javascript/dashboard/store/modules/funnels/mutations.js`
- `app/javascript/dashboard/store/modules/funnels/getters.js`
- `app/javascript/dashboard/store/modules/funnels/types.js`

#### 4.2 API Client
- ✅ Classe `FunnelsAPI` para comunicação com backend
- ✅ Métodos para todas as operações CRUD
- ✅ Métodos específicos para drag-and-drop

**Arquivos:**
- `app/javascript/dashboard/api/funnels.js`

### 5. Internacionalização

- ✅ Traduções em português (pt_BR)
- ✅ Traduções em inglês (en)
- ✅ Todas as strings da interface traduzidas

**Arquivos:**
- `app/javascript/dashboard/i18n/locale/pt_BR/contact.json`
- `app/javascript/dashboard/i18n/locale/en/contact.json`

### 6. Funil Padrão

- ✅ Criação automática do funil "geral" quando não existem funis
- ✅ Colunas padrão pré-configuradas:
  - Recentes
  - Backlog
  - Prioridade
  - Em Execução
  - Aguardando Terceiros

---

## ⚠️ Funcionalidades Implementadas mas Não Testadas/Refinadas

### 1. Drag and Drop

**Status:** Implementado no código, mas pode precisar de ajustes

**O que foi feito:**
- ✅ Atributos `draggable="true"` nos cards
- ✅ Handlers `dragstart`, `dragover`, `drop` implementados
- ✅ Feedback visual durante o arrasto
- ✅ Cálculo de posição baseado na posição do drop
- ✅ Suporte para arrastar da sidebar para colunas

**Arquivos modificados:**
- `KanbanCard.vue` - handlers de drag
- `KanbanColumn.vue` - handlers de drop
- `ContactsSidebar.vue` - drag da sidebar

**Possíveis problemas:**
- Pode haver conflitos com eventos de click
- Posicionamento pode não estar preciso
- Pode não estar salvando corretamente no backend

### 2. Menus de Opções

**Status:** Estrutura criada, funcionalidades básicas implementadas

**O que foi feito:**
- ✅ Menu dropdown nas colunas (botão "..." no cabeçalho)
- ✅ Menu dropdown nos cards (botão "..." no card)
- ✅ Fechamento ao clicar fora
- ✅ Opções: "Ver contato", "Remover do funil"

**Arquivos modificados:**
- `KanbanColumn.vue` - menu de coluna
- `KanbanCard.vue` - menu de card

**Funcionalidades pendentes:**
- Editar coluna (apenas estrutura)
- Excluir coluna (apenas estrutura)
- Mais opções nos menus

### 3. Adicionar Contato ao Funil

**Status:** Implementado, mas pode precisar de testes

**O que foi feito:**
- ✅ Botão "+" na sidebar para adicionar contato
- ✅ Handler `handleAddContact` implementado
- ✅ Adiciona na primeira coluna do funil
- ✅ Recarrega contatos após adicionar

**Possíveis problemas:**
- Pode não estar atualizando a UI corretamente
- Pode não estar removendo da sidebar após adicionar

### 4. Busca e Filtros

**Status:** Busca básica implementada, filtros não

**O que foi feito:**
- ✅ Campo de busca no header
- ✅ Filtragem de contatos por nome, email, telefone
- ✅ Botão de filtro (mostra mensagem "em breve")

**Pendente:**
- Filtros avançados
- Filtros por atributos customizados

---

## 🎨 Design e Estilo

### Cores

- ✅ Cor principal alterada de verde para **teal**
- ✅ Consistência visual com o design system
- ✅ Uso de classes Tailwind do projeto

### Layout

- ✅ Sidebar fixa à esquerda (300px)
- ✅ Área principal com scroll horizontal
- ✅ Colunas com largura fixa (320px)
- ✅ Cards com sombra e hover effects

---

## 📁 Estrutura de Arquivos Criados/Modificados

### Backend (Ruby on Rails)

```
app/
├── controllers/
│   └── api/v1/accounts/
│       ├── funnels_controller.rb
│       └── funnels/
│           └── funnel_contacts_controller.rb
├── models/
│   ├── funnel.rb
│   └── funnel_contact.rb
├── policies/
│   ├── funnel_policy.rb
│   └── funnel_contact_policy.rb
└── views/
    └── api/v1/
        ├── models/
        │   └── _funnel.json.jbuilder
        └── accounts/
            └── funnels/
                ├── index.json.jbuilder
                └── funnel_contacts/
                    └── index.json.jbuilder

db/
└── migrate/
    ├── 20250115000000_create_funnels.rb
    └── 20250115000001_create_funnel_contacts.rb

config/
└── routes.rb (modificado)
```

### Frontend (Vue.js)

```
app/javascript/dashboard/
├── api/
│   └── funnels.js
├── components-next/
│   └── Contacts/
│       └── Kanban/
│           ├── KanbanView.vue
│           ├── KanbanColumn.vue
│           ├── KanbanCard.vue
│           ├── ContactsSidebar.vue
│           └── CreateFunnelDialog.vue
├── routes/
│   └── dashboard/
│       └── contacts/
│           └── pages/
│               └── ContactsIndex.vue (modificado)
├── store/
│   └── modules/
│       └── funnels/
│           ├── index.js
│           ├── actions.js
│           ├── mutations.js
│           ├── getters.js
│           └── types.js
└── i18n/
    └── locale/
        ├── pt_BR/
        │   └── contact.json (modificado)
        └── en/
            └── contact.json (modificado)
```

---

## 🔧 Configurações e Dependências

### Rotas

```ruby
resources :funnels, only: [:index, :show, :create, :update, :destroy] do
  resources :funnel_contacts, only: [:index, :create, :update, :destroy], 
             param: :contact_id, module: :funnels
  post :move_contact, on: :member
end
```

### Dependências

- Nenhuma dependência externa adicional necessária
- Usa bibliotecas já presentes no projeto (Vue 3, Vuex, Vue Router, Tailwind)

---

## 🐛 Problemas Conhecidos e Limitações

### 1. Drag and Drop
- Pode não estar salvando a posição corretamente
- Pode haver conflitos entre drag e click
- Feedback visual pode não estar funcionando em todos os casos

### 2. Atualização de Estado
- A UI pode não estar atualizando imediatamente após operações
- Pode ser necessário recarregar manualmente em alguns casos

### 3. Performance
- Não otimizado para grandes volumes de contatos
- Pode ser lento com muitos funis/colunas

### 4. Funcionalidades Incompletas
- Edição de colunas não implementada
- Exclusão de colunas não implementada
- Filtros avançados não implementados
- Cálculo de valores (R$ 0,00) não implementado

---

## 📝 Próximos Passos Recomendados

### Prioridade Alta
1. **Testar e corrigir drag and drop**
   - Verificar se está salvando corretamente
   - Ajustar posicionamento
   - Melhorar feedback visual

2. **Testar adição de contatos**
   - Verificar se está removendo da sidebar
   - Verificar se está atualizando a UI
   - Testar edge cases

3. **Implementar remoção de contatos**
   - Verificar se o menu está funcionando
   - Testar a ação de remover

### Prioridade Média
4. **Implementar edição de colunas**
   - Diálogo para editar nome
   - Reordenação de colunas

5. **Implementar exclusão de colunas**
   - Confirmação antes de excluir
   - Mover contatos para outra coluna

6. **Melhorar busca e filtros**
   - Filtros avançados
   - Filtros por atributos

### Prioridade Baixa
7. **Cálculo de valores**
   - Implementar lógica de cálculo
   - Exibir valores reais nas colunas

8. **Otimizações de performance**
   - Virtual scrolling para muitos contatos
   - Lazy loading de dados

---

## 🧪 Como Testar

### Testes Básicos (Funcionando)

1. **Acessar a página Kanban**
   ```
   - Navegar para Contatos
   - Clicar na aba "Kanban"
   - Verificar se a página carrega
   ```

2. **Verificar exibição de contatos**
   ```
   - Verificar se a sidebar mostra contatos
   - Verificar se os cards aparecem nas colunas
   - Verificar se os dados estão corretos
   ```

3. **Verificar funil padrão**
   ```
   - Verificar se o funil "geral" foi criado
   - Verificar se as colunas padrão aparecem
   ```

### Testes Avançados (Precisam de Validação)

4. **Testar drag and drop**
   ```
   - Arrastar card entre colunas
   - Verificar se salva no backend
   - Verificar se a UI atualiza
   ```

5. **Testar adicionar contato**
   ```
   - Clicar no botão "+" na sidebar
   - Verificar se adiciona ao funil
   - Verificar se remove da sidebar
   ```

6. **Testar menus**
   ```
   - Clicar no "..." do card
   - Verificar se o menu abre
   - Testar "Ver contato"
   - Testar "Remover do funil"
   ```

---

## 📚 Referências

### Arquivos de Configuração
- `config/routes.rb` - Rotas da API
- `tailwind.config.js` - Configuração de cores (teal)

### Documentação do Projeto
- [Chatwoot Development Guidelines](./README.md)
- [Enterprise Edition Development](https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38)

---

## ✅ Conclusão

**O que está funcionando:**
- ✅ Criação da página Kanban
- ✅ Exibição de contatos na sidebar
- ✅ Exibição de cards nas colunas
- ✅ Estrutura backend completa
- ✅ API REST funcional
- ✅ Estado gerenciado no Vuex

**O que precisa de trabalho:**
- ⚠️ Drag and drop (implementado, mas não testado completamente)
- ⚠️ Menus de opções (estrutura criada, funcionalidades básicas)
- ⚠️ Adição de contatos (implementado, mas pode precisar de ajustes)
- ⚠️ Atualização de UI após operações

**Recomendação:** Focar em testar e corrigir as funcionalidades básicas antes de adicionar novas features.

---

*Documento criado em: Janeiro 2025*
*Última atualização: Janeiro 2025*

