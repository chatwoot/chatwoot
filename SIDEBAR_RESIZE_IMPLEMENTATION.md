# Implementação de Redimensionamento da Sidebar

## Resumo

Foi implementada a funcionalidade de redimensionamento da sidebar principal do dashboard, permitindo que o usuário ajuste a largura da barra lateral através de arraste, com persistência da preferência no `localStorage`.

## Arquivo Modificado

- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

## Mudanças Realizadas

### 1. Imports Adicionados

```javascript
import { ref } from 'vue';
import { useWindowSize } from '@vueuse/core';
```

**Linhas:** 2 e 9

**Motivo:** 
- `ref` é necessário para criar estados reativos (`isResizing`, `resizeStartX`, `resizeStartWidth`)
- `useWindowSize` é usado para detectar o tamanho da janela e determinar se estamos no desktop ou mobile

### 2. Estado de Redimensionamento

**Linhas:** 99-108

```javascript
// Sidebar resize functionality
const { width: windowWidth } = useWindowSize();
const sidebarWidth = useStorage('next-sidebar-width', 200);
const MIN_WIDTH = 250;
const MAX_WIDTH = 400;
const isResizing = ref(false);
const resizeStartX = ref(0);
const resizeStartWidth = ref(200);

const isDesktop = computed(() => windowWidth.value >= 768);
```

**Explicação:**
- `sidebarWidth`: Armazena a largura atual da sidebar no `localStorage` (padrão: 200px)
- `MIN_WIDTH`: Largura mínima permitida (250px)
- `MAX_WIDTH`: Largura máxima permitida (400px)
- `isResizing`: Flag que indica se o usuário está redimensionando
- `resizeStartX`: Posição X do mouse quando o redimensionamento começou
- `resizeStartWidth`: Largura da sidebar quando o redimensionamento começou
- `isDesktop`: Computed que verifica se estamos em desktop (≥768px)

### 3. Função `startResize`

**Linhas:** 110-124

```javascript
const startResize = event => {
  // Only allow resize on desktop (md and above)
  if (!isDesktop.value) return;
  
  isResizing.value = true;
  resizeStartX.value = event.clientX;
  resizeStartWidth.value = sidebarWidth.value;
  
  document.addEventListener('mousemove', handleResize);
  document.addEventListener('mouseup', stopResize);
  document.body.style.cursor = 'col-resize';
  document.body.style.userSelect = 'none';
  
  event.preventDefault();
};
```

**Explicação:**
- Verifica se estamos no desktop antes de permitir redimensionamento
- Inicia o estado de redimensionamento
- Salva a posição inicial do mouse e a largura atual
- Adiciona listeners para `mousemove` e `mouseup`
- Muda o cursor para `col-resize` e desabilita seleção de texto
- Previne o comportamento padrão do evento

### 4. Função `handleResize`

**Linhas:** 126-137

```javascript
const handleResize = event => {
  if (!isResizing.value) return;
  
  const deltaX = event.clientX - resizeStartX.value;
  const isRTL = document.documentElement.dir === 'rtl';
  const newWidth = isRTL 
    ? resizeStartWidth.value - deltaX 
    : resizeStartWidth.value + deltaX;
  
  const clampedWidth = Math.max(MIN_WIDTH, Math.min(MAX_WIDTH, newWidth));
  sidebarWidth.value = clampedWidth;
};
```

**Explicação:**
- Calcula a diferença de movimento do mouse (`deltaX`)
- Detecta se o layout é RTL (Right-to-Left)
- Calcula a nova largura (invertendo o delta em RTL)
- Aplica limites mínimo e máximo
- Atualiza a largura da sidebar

### 5. Função `stopResize`

**Linhas:** 139-145

```javascript
const stopResize = () => {
  isResizing.value = false;
  document.removeEventListener('mousemove', handleResize);
  document.removeEventListener('mouseup', stopResize);
  document.body.style.cursor = '';
  document.body.style.userSelect = '';
};
```

**Explicação:**
- Finaliza o estado de redimensionamento
- Remove os event listeners
- Restaura o cursor e a seleção de texto

### 6. Computed `sidebarStyle`

**Linhas:** 147-154

```javascript
const sidebarStyle = computed(() => {
  // Only apply custom width on desktop (md and above)
  if (!isDesktop.value) return {};
  return {
    width: `${sidebarWidth.value}px`,
    flexBasis: `${sidebarWidth.value}px`,
  };
});
```

**Explicação:**
- Retorna um objeto vazio no mobile (mantém comportamento original)
- No desktop, retorna estilos inline com a largura customizada
- Aplica tanto `width` quanto `flexBasis` para garantir compatibilidade

### 7. Modificação no Template - Elemento `<aside>`

**Linha:** 656

```vue
:style="sidebarStyle"
```

**Explicação:**
- Adiciona binding de estilo dinâmico ao elemento `<aside>`
- Aplica a largura customizada apenas no desktop

### 8. Handle de Redimensionamento no Template

**Linhas:** 658-664

```vue
<!-- Resize handle - only visible on desktop -->
<div
  class="hidden md:block absolute top-0 bottom-0 ltr:right-0 rtl:left-0 w-1 cursor-col-resize hover:bg-n-strong/50 transition-colors z-50 group"
  @mousedown="startResize"
>
  <div class="absolute inset-y-0 ltr:-right-1 rtl:-left-1 w-3" />
</div>
```

**Explicação:**
- `hidden md:block`: Visível apenas no desktop (oculto no mobile)
- `absolute`: Posicionamento absoluto na borda da sidebar
- `ltr:right-0 rtl:left-0`: Posiciona na borda direita (LTR) ou esquerda (RTL)
- `cursor-col-resize`: Cursor indica redimensionamento
- `hover:bg-n-strong/50`: Feedback visual ao passar o mouse
- `@mousedown="startResize"`: Inicia o redimensionamento ao clicar
- O `div` interno aumenta a área clicável para facilitar o uso

## Comportamento

### Desktop (≥768px)
- A sidebar pode ser redimensionada arrastando a borda direita (ou esquerda em RTL)
- A largura é limitada entre 250px e 400px
- A preferência é salva no `localStorage` e persiste entre sessões
- O cursor muda para `col-resize` ao passar sobre o handle

### Mobile (<768px)
- O redimensionamento está desabilitado
- A sidebar mantém o comportamento original (largura fixa de 200px)
- O handle de redimensionamento não é exibido

## Personalização

### Alterar Largura Mínima/Máxima

Edite as constantes nas linhas 102-103:

```javascript
const MIN_WIDTH = 250;  // Altere para o valor desejado
const MAX_WIDTH = 400;  // Altere para o valor desejado
```

### Alterar Largura Padrão

Edite o valor padrão na linha 101:

```javascript
const sidebarWidth = useStorage('next-sidebar-width', 200); // Altere 200 para o valor desejado
```

### Alterar Chave do LocalStorage

Edite a chave na linha 101:

```javascript
const sidebarWidth = useStorage('next-sidebar-width', 200); // Altere 'next-sidebar-width' para outra chave
```

## Suporte RTL

A implementação suporta layouts Right-to-Left:
- O handle aparece na borda esquerda em RTL
- O cálculo da largura é invertido corretamente
- As classes Tailwind `ltr:` e `rtl:` garantem posicionamento correto

## Testes Recomendados

1. **Redimensionamento básico:**
   - Arraste a borda da sidebar no desktop
   - Verifique se a largura muda suavemente
   - Verifique se os limites mínimo/máximo são respeitados

2. **Persistência:**
   - Redimensione a sidebar
   - Recarregue a página
   - Verifique se a largura foi mantida

3. **Mobile:**
   - Redimensione a janela para <768px
   - Verifique se o handle desaparece
   - Verifique se a sidebar mantém largura fixa

4. **RTL:**
   - Teste em um layout RTL
   - Verifique se o handle aparece na borda correta
   - Verifique se o redimensionamento funciona corretamente

## Notas Técnicas

- Usa `useStorage` do VueUse para persistência automática
- Usa `useWindowSize` para detecção reativa do tamanho da janela
- Não afeta o comportamento mobile existente
- Compatível com o sistema de design existente (Tailwind)
- Não adiciona dependências externas

## Data da Implementação

Implementado em: [Data atual]

## Autor

Implementado conforme solicitação do usuário para controle total da largura da sidebar.

