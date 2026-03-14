---
name: master-front-skill
description: "Master frontend skill: Tailwind v4, shadcn/ui, design system, performance React e acessibilidade. Use ao criar/revisar UI, configurar Tailwind v4 + shadcn/ui, otimizar performance ou auditar acessibilidade."
---

# Master Front Skill

Você é um engenheiro frontend sênior com visão de design system e obsessão por performance. Esta skill consolida as melhores práticas de UI, Tailwind v4, shadcn/ui, acessibilidade, performance React e animações.

## Quando Usar

- Criar qualquer componente, página, dashboard, landing page
- Configurar Tailwind v4 + shadcn/ui (setup, dark mode, tokens)
- Revisar ou auditar UI (acessibilidade, UX, performance)
- Corrigir erros de Tailwind v4 (`bg-primary` não funciona, dark mode, `@apply`, animações)
- Otimizar performance React/Next.js (bundle, re-renders, waterfalls)
- Criar animações ou vídeo com Remotion
- Documentar design system (DESIGN.md)

---

> A nata de todas as skills de frontend: frontend-design · design-md · tailwind-theme-builder · shadcn-ui · web-design-guidelines · remotion-best-practices · vercel-react-best-practices

---

## 1. Filosofia de Design — Não Crie "AI Slop"

Antes de codar, escolha uma **direção estética deliberada** e a execute com precisão. Design sem ponto de vista é design esquecível.

### Perguntas obrigatórias antes de começar

- **Propósito**: Que problema essa interface resolve? Quem usa?
- **Tom**: Escolha um extremo — brutal/minimalista, maximalista, retro-futurista, orgânico, luxuoso, lúdico, editorial, brutalista, art déco, industrial. Execute COM CONVICÇÃO.
- **Diferencial**: O que torna essa UI **inesquecível**?

### O que evitar absolutamente

| ❌ Proibido | ✅ Em vez disso |
|---|---|
| Inter, Roboto, Arial, system fonts | Fontes com caráter (display + corpo refinado) |
| Gradiente roxo em fundo branco | Paleta dominante com acento afiado |
| Layouts previsíveis e centrados | Assimetria, sobreposição, fluxo diagonal |
| Micro-interações espalhadas | 1 entrada de página bem orquestrada (stagger) |
| Fundos sólidos genéricos | Gradient meshes, noise textures, transparências |

### Regras de Estética

- **Tipografia**: Par fonte display (caracter) + corpo (refinada). Nunca use fontes genéricas.
- **Cor**: CSS variables para consistência. Cores dominantes com acentos nítidos > paleta equilibrada e tímida.
- **Motion**: CSS-only para HTML. `motion` library para React. Foque em momentos de alto impacto — entrada com stagger, hover states que surpreendem, scroll-triggered.
- **Composição espacial**: Espaço negativo generoso **ou** densidade controlada. Elementos que quebram o grid.
- **Fundo e profundidade**: Crie atmosfera — gradient meshes, noise, padrões geométricos, sombras dramáticas, grain overlays.

---

## 2. Tailwind v4 — Arquitetura CSS (CORE)

### Setup Inicial

```bash
pnpm add tailwindcss @tailwindcss/vite
pnpm add -D @types/node tw-animate-css
pnpm dlx shadcn@latest init
rm -f tailwind.config.ts  # v4 não usa isso
```

### Configurar Vite

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: { alias: { '@': path.resolve(__dirname, './src') } }
})
```

### A Arquitetura de 4 Passos (OBRIGATÓRIA)

Esta ordem exata é mandatória. Qualquer desvio quebra o tema.

```css
/* src/index.css */
@import "tailwindcss";
@import "tw-animate-css";

/* PASSO 1: Variáveis CSS no root (NUNCA dentro de @layer base) */
:root {
  --background: hsl(0 0% 100%);
  --foreground: hsl(222.2 84% 4.9%);
  --card: hsl(0 0% 100%);
  --card-foreground: hsl(222.2 84% 4.9%);
  --primary: hsl(221.2 83.2% 53.3%);
  --primary-foreground: hsl(210 40% 98%);
  --secondary: hsl(210 40% 96%);
  --secondary-foreground: hsl(222.2 47.4% 11.2%);
  --muted: hsl(210 40% 96%);
  --muted-foreground: hsl(215.4 16.3% 46.9%);
  --accent: hsl(210 40% 96%);
  --accent-foreground: hsl(222.2 47.4% 11.2%);
  --destructive: hsl(0 84.2% 60.2%);
  --border: hsl(214.3 31.8% 91.4%);
  --input: hsl(214.3 31.8% 91.4%);
  --ring: hsl(221.2 83.2% 53.3%);
  --radius: 0.5rem;
}

.dark {
  --background: hsl(222.2 84% 4.9%);
  --foreground: hsl(210 40% 98%);
  --primary: hsl(217.2 91.2% 59.8%);
  --primary-foreground: hsl(222.2 47.4% 11.2%);
  /* ... outros overrides dark */
}

/* PASSO 2: Mapear variáveis para utilities do Tailwind */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-destructive: var(--destructive);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
}

/* PASSO 3: Estilos base (SEM hsl() aqui — já está nas variáveis) */
@layer base {
  * {
    border-color: var(--border);
  }
  body {
    background-color: var(--background);
    color: var(--foreground);
  }
}
```

**Resultado**: `bg-background`, `text-primary`, `bg-card` etc. funcionam. Dark mode via `.dark` class — sem `dark:` variants para cores semânticas.

### components.json (v4)

```json
{
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  }
}
```

`"config": ""` é CRÍTICO — v4 não usa tailwind.config.ts.

---

## 3. Tailwind v4 — Armadilhas Críticas

| Sintoma | Causa | Fix |
|---|---|---|
| `bg-primary` não funciona | Falta `@theme inline` | Adicionar bloco `@theme inline` |
| Cores viram preto/branco | Double `hsl()` wrapping | Usar `var(--color)` direto |
| Dark mode não muda | ThemeProvider ausente | Envolver app em `<ThemeProvider>` |
| Build falha | `tailwind.config.ts` com tema | Deletar o arquivo |
| Erro de animação | `tailwindcss-animate` (deprecated) | Usar `tw-animate-css` |
| `@apply` quebra em classe custom | v4 breaking change | Usar `@utility` em vez de `@layer components` |
| Duplicate `@layer base` | shadcn init adiciona um extra | Mesclar em um único bloco |

### Regras Absolutas

**Sempre:**
- Envolver cores com `hsl()` em `:root`/`.dark`
- Usar `@theme inline` para mapear TODAS as variáveis CSS
- Usar `@tailwindcss/vite` (NÃO PostCSS)
- Deletar `tailwind.config.ts` se existir

**Nunca:**
- Colocar `:root`/`.dark` dentro de `@layer base`
- Usar `.dark { @theme { } }` (v4 não suporta nested @theme)
- Double-wrap: `hsl(var(--background))` — já tem hsl
- Cores hardcoded: `bg-blue-600 dark:bg-blue-400` → usar semântico `bg-primary`

---

## 4. Dark Mode Canônico

### ThemeProvider

```typescript
// src/components/theme-provider.tsx
import { createContext, useContext, useEffect, useState, ReactNode } from 'react'

type Theme = 'dark' | 'light' | 'system'

const ThemeProviderContext = createContext<{
  theme: Theme
  setTheme: (theme: Theme) => void
}>({ theme: 'system', setTheme: () => null })

export function ThemeProvider({
  children,
  defaultTheme = 'system',
  storageKey = 'ui-theme',
}: {
  children: ReactNode
  defaultTheme?: Theme
  storageKey?: string
}) {
  const [theme, setTheme] = useState<Theme>(() => {
    try { return (localStorage.getItem(storageKey) as Theme) || defaultTheme }
    catch { return defaultTheme }
  })

  useEffect(() => {
    const root = window.document.documentElement
    root.classList.remove('light', 'dark')
    if (theme === 'system') {
      root.classList.add(window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
      return
    }
    root.classList.add(theme)
  }, [theme])

  return (
    <ThemeProviderContext.Provider value={{
      theme,
      setTheme: (t) => {
        try { localStorage.setItem(storageKey, t) } catch {}
        setTheme(t)
      }
    }}>
      {children}
    </ThemeProviderContext.Provider>
  )
}

export const useTheme = () => useContext(ThemeProviderContext)
```

### ModeToggle (shadcn/ui)

```typescript
// src/components/mode-toggle.tsx
import { Moon, Sun } from "lucide-react"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { useTheme } from "@/components/theme-provider"

export function ModeToggle() {
  const { setTheme } = useTheme()
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="icon">
          <Sun className="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("light")}>Light</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dark")}>Dark</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("system")}>System</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

---

## 5. shadcn/ui — Sistema de Componentes

### Princípios

shadcn/ui **não é uma biblioteca** — é código que você copia para seu projeto. Você tem propriedade total, customização completa, sem vendor lock-in.

### Estrutura de Arquivos

```
src/
├── components/
│   ├── ui/           # componentes shadcn (não editar diretamente)
│   │   ├── button.tsx
│   │   ├── dialog.tsx
│   └── [feature]/    # compostos customizados
│       └── loading-button.tsx
├── lib/
│   └── utils.ts      # cn() — único lugar
└── app/
```

### O Utilitário `cn()` — Sempre Usar

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

```tsx
// ❌ Errado
<div className={`base ${isActive && 'active'}`} />

// ✅ Correto
<div className={cn("base", isActive && "active")} />
```

### Variantes com CVA

```typescript
import { cva, type VariantProps } from "class-variance-authority"

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md font-medium transition-colors",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        outline: "border border-input bg-background hover:bg-accent",
        ghost: "hover:bg-accent hover:text-accent-foreground",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3 text-sm",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  }
)
```

### Extender Componentes (Correto)

```typescript
// components/loading-button.tsx — FORA de components/ui/
import { Button, type ButtonProps } from "@/components/ui/button"
import { Loader2 } from "lucide-react"

export function LoadingButton({ loading, children, ...props }: ButtonProps & { loading?: boolean }) {
  return (
    <Button disabled={loading} {...props}>
      {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
      {children}
    </Button>
  )
}
```

### Padrões Comuns

```tsx
// Dialog (SEMPRE shadcn, NUNCA alert()/confirm())
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"

// Toast
import { toast } from "sonner"
toast.promise(promise, { loading: 'Salvando...', success: 'Salvo!', error: 'Erro!' })

// Form com react-hook-form
import { useForm } from "react-hook-form"
import { Form, FormControl, FormField, FormItem, FormLabel } from "@/components/ui/form"
```

---

## 6. Sistema de Design Semântico (DESIGN.md)

Ao documentar um design system, use linguagem descritiva — nunca técnica bruta.

### Estrutura DESIGN.md

```markdown
# Design System: [Nome]

## 1. Atmosfera Visual
(Humor, densidade, filosofia estética — "Arejado", "Denso", "Minimalista")

## 2. Paleta de Cores
- Ocean-deep Cerulean (#0077B6) — ações primárias
- Ivory Whisper (#F8F4EF) — superfícies de fundo

## 3. Tipografia
(Família, peso para títulos vs corpo, letter-spacing)

## 4. Componentes
- Botões: forma, cor, comportamento
- Cards: arredondamento, fundo, sombra
- Inputs: estilo de borda, fundo

## 5. Layout
(Estratégia de espaço branco, margens, alinhamento de grid)
```

### Regras de Nomenclatura Semântica

| ❌ Técnico | ✅ Descritivo |
|---|---|
| `rounded-xl` | "Cantos generosamente arredondados" |
| `rounded-full` | "Formato de pílula" |
| `rounded-none` | "Bordas retas e quadradas" |
| `shadow-lg` | "Sombra profunda de alto contraste" |
| `shadow-sm` | "Elevação sussurada e difusa" |
| `#0077B6` | "Cerulean oceânico (#0077B6)" |

---

## 7. Performance React/Next.js — Regras por Prioridade

### P1 — CRÍTICO: Eliminar Waterfalls

```typescript
// ❌ Waterfall sequencial
const user = await getUser()
const posts = await getPosts(user.id)  // espera user

// ✅ Paralelo com Promise.all
const [user, config] = await Promise.all([getUser(), getConfig()])

// ✅ Await tardio — inicie promises cedo
const userPromise = getUser()
const postsPromise = getPosts()
// ... lógica ...
const [user, posts] = await Promise.all([userPromise, postsPromise])

// ✅ Suspense para streaming
<Suspense fallback={<Skeleton />}>
  <AsyncComponent />
</Suspense>
```

### P2 — CRÍTICO: Tamanho do Bundle

```typescript
// ❌ Barrel imports (importa o módulo inteiro)
import { debounce } from 'lodash'

// ✅ Import direto
import debounce from 'lodash/debounce'

// ✅ Dynamic import para componentes pesados
const HeavyChart = dynamic(() => import('./HeavyChart'), { ssr: false })

// ✅ Defer libraries não-críticas após hidratação
useEffect(() => {
  import('./analytics').then(m => m.init())
}, [])

// ✅ Preload on hover para perceived performance
const handleMouseEnter = () => import('./HeavyModal')
```

### P3 — ALTO: Performance Server-Side

```typescript
// ✅ React.cache() para deduplicação por request
import { cache } from 'react'
const getUser = cache(async (id: string) => db.user.findUnique({ where: { id } }))

// ✅ Minimize props serializadas em RSC
// Passe apenas o que o Client Component precisa, não objetos inteiros

// ✅ after() para operações não-bloqueantes
import { after } from 'next/server'
after(() => logAnalytics(event))  // não bloqueia a resposta
```

### P4 — MÉDIO-ALTO: Data Fetching Client

```typescript
// ✅ SWR com deduplicação e configuração correta
const { data, isLoading } = useSWR('/api/users', fetcher, {
  revalidateOnFocus: true,
  dedupingInterval: 1500,
  keepPreviousData: true,  // evita FOEC (Flash of Empty Content)
})

// ✅ FOEC — SEMPRE desestruturar isLoading
if (isLoading) return <Skeleton />
// ❌ NÃO: data?.items || [] cria flash de estado vazio

// ✅ Passive event listeners para scroll
el.addEventListener('scroll', handler, { passive: true })
```

### P5 — MÉDIO: Otimização de Re-renders

```typescript
// ✅ Usar ternário, NUNCA && para JSX condicional
// ❌ {count && <Component />}  — renderiza "0" quando count=0
// ✅ {count ? <Component /> : null}

// ✅ useTransition para updates não-urgentes
const [isPending, startTransition] = useTransition()
startTransition(() => setFilter(value))

// ✅ Estado derivado durante render, não em useEffect
const filteredItems = useMemo(() => items.filter(pred), [items, pred])

// ✅ useRef para valores transientes de alta frequência
const mousePosition = useRef({ x: 0, y: 0 })

// ✅ setState funcional para callbacks estáveis
setState(prev => ({ ...prev, count: prev.count + 1 }))

// ✅ Hoist JSX estático fora do componente
const STATIC_ICON = <CheckIcon className="h-4 w-4" />  // não re-cria
function MyComponent() { return <div>{STATIC_ICON}</div> }
```

### P6 — MÉDIO: Rendering

```typescript
// ✅ content-visibility para listas longas
// CSS: content-visibility: auto; contain-intrinsic-size: 0 200px;

// ✅ Animar wrapper div, não SVG direto
// ❌ <motion.svg> — causa reflow
// ✅ <motion.div><svg /></motion.div>

// ✅ Lazy state initialization para valores custosos
const [state, setState] = useState(() => expensiveComputation())

// ✅ Activity component para show/hide sem desmontar
<Activity mode={isVisible ? 'visible' : 'hidden'}>
  <ExpensivePanel />
</Activity>
```

### P7 — BAIXO-MÉDIO: JavaScript

```typescript
// ✅ Set/Map para lookups O(1) em grandes coleções
const userMap = new Map(users.map(u => [u.id, u]))
const user = userMap.get(id)  // O(1) vs O(n)

// ✅ Hoist RegExp fora de loops
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/  // no módulo
function validate(email: string) { return EMAIL_RE.test(email) }

// ✅ Early exit
function process(items: Item[]) {
  if (!items.length) return []
  // ...
}

// ✅ toSorted() para imutabilidade
const sorted = items.toSorted((a, b) => a.name.localeCompare(b.name))
```

---

## 8. Acessibilidade & UX (Web Interface Guidelines)

### Checklist de Acessibilidade

- [ ] **Contraste**: mínimo 4.5:1 para texto normal, 3:1 para texto grande e UI
- [ ] **Navegação por teclado**: Tab order lógico, foco visível em todos os interativos
- [ ] **ARIA**: atributos em componentes customizados, roles corretos
- [ ] **Focus management**: Dialog/Modal gerencia foco ao abrir/fechar
- [ ] **Imagens**: `alt` descritivo ou `alt=""` para decorativas
- [ ] **Formulários**: `label` associado a cada `input`
- [ ] **Sem `disabled` em links**: use `aria-disabled` + preventDefault
- [ ] **Screen reader**: testar com VoiceOver/NVDA

### Padrões de UX

- **Dialogs**: SEMPRE shadcn/ui `<Dialog>` — NUNCA `alert()` ou `confirm()` nativos
- **Loading states**: `useTransition` para não-urgente, `Suspense` para async, skeleton para dados
- **Optimistic UI**: atualize a UI antes da resposta do servidor, rollback on error
- **Toast**: `toast.promise()` do sonner para operações assíncronas
- **Formulários**: react-hook-form + zod para validação; mostre erros inline, não em alert

### Verificação de Contraste WCAG

```css
/* Tokens com pares foreground obrigatórios */
--primary: hsl(221 83% 53%);
--primary-foreground: hsl(210 40% 98%);  /* SEMPRE par com foreground */

--destructive: hsl(0 84% 60%);
--destructive-foreground: hsl(0 0% 100%);
```

---

## 9. Animações & Motion

### React / Framer Motion

```tsx
// ✅ Stagger entry — mais impacto que micro-interações espalhadas
const container = { hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.1 } } }
const item = { hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map(i => <motion.li key={i.id} variants={item} />)}
</motion.ul>

// ✅ GPU-friendly: usar transform/opacity, nunca left/top/width
// ❌ left, top, margin, padding em animações
// ✅ translateX, translateY, scale, opacity

// ✅ Animar wrapper, não SVG diretamente
<motion.div whileHover={{ scale: 1.05 }}>
  <svg />
</motion.div>
```

### Tailwind Animations (v4)

```css
/* Usar tw-animate-css para animações pré-definidas */
@import "tw-animate-css";

/* Definir animações customizadas em @theme inline */
@theme inline {
  --animate-fade-in: fade-in 0.3s ease-out;
  --animate-slide-up: slide-up 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes fade-in {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### Remotion (Video React)

```tsx
// ✅ useCurrentFrame() para animações baseadas em frame
import { useCurrentFrame, interpolate, spring, useVideoConfig } from 'remotion'

function AnimatedTitle() {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()

  const opacity = spring({ frame, fps, config: { damping: 200 } })
  const translateY = interpolate(frame, [0, 30], [50, 0], {
    extrapolateRight: 'clamp'
  })

  return (
    <div style={{ opacity, transform: `translateY(${translateY}px)` }}>
      Título Animado
    </div>
  )
}

// ✅ Sequence para timing declarativo
<Sequence from={30} durationInFrames={60}>
  <Subtitle />
</Sequence>

// ✅ Img (não <img>) para preload correto em Remotion
import { Img } from 'remotion'
<Img src={staticFile('logo.png')} />
```

---

## 10. Composição de Componentes

### Evitar Props Booleanas que Proliferam

```tsx
// ❌ Boolean prop hell
<Button primary outline large rounded loading disabled />

// ✅ Variants explícitas com CVA
<Button variant="outline" size="lg" />

// ✅ Compound components para UI complexa
<Dialog>
  <Dialog.Trigger>Abrir</Dialog.Trigger>
  <Dialog.Content>
    <Dialog.Header>Título</Dialog.Header>
  </Dialog.Content>
</Dialog>
```

### React 19 — Sem forwardRef

```tsx
// ❌ React 18
const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => (
  <input ref={ref} {...props} />
))

// ✅ React 19 — ref como prop direta
function Input({ ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />
}
```

### Context com Interface Tipada

```tsx
// ✅ Context com interface explícita
interface ThemeContextType {
  theme: 'light' | 'dark'
  toggle: () => void
}

const ThemeContext = createContext<ThemeContextType | null>(null)

export function useThemeContext() {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error('useThemeContext deve estar dentro de ThemeProvider')
  return ctx
}
```

---

## 11. Checklist de Deploy

### CSS / Tailwind

- [ ] `tailwind.config.ts` deletado ou vazio
- [ ] `components.json` com `"config": ""`
- [ ] Todas cores com `hsl()` em `:root`/`.dark`
- [ ] `@theme inline` mapeia TODAS as variáveis
- [ ] `@layer base` não envolve `:root`
- [ ] Nenhum `@layer base` duplicado
- [ ] ThemeProvider envolve o app

### Performance

- [ ] Sem imports de barrel (`import { x } from 'lib'`)
- [ ] Componentes pesados com `dynamic()`
- [ ] Fetches independentes em `Promise.all()`
- [ ] Suspense boundaries estratégicas
- [ ] `keepPreviousData: true` em listas SWR

### Qualidade

- [ ] `tsc --noEmit` sem erros
- [ ] Testado em Light + Dark + System mode
- [ ] Contraste WCAG 4.5:1 em todo texto
- [ ] Dialog/Modal com keyboard navigation
- [ ] Sem `alert()` ou `confirm()` no código
- [ ] Semantic tokens usados, sem hardcode de cor
- [ ] `cn()` em todos os className condicionais

---

## Referência Rápida — Skill para Cada Cenário

| Tarefa | Skill Aplicada |
|---|---|
| Iniciar projeto Tailwind v4 + shadcn | `tailwind-theme-builder` |
| Criar UI com personalidade visual forte | `frontend-design` |
| Adicionar/customizar componentes shadcn | `shadcn-ui` |
| Documentar design system existente | `design-md` |
| Review de acessibilidade e UX | `web-design-guidelines` |
| Otimizar performance React/Next.js | `vercel-react-best-practices` |
| Criar vídeo/animação programática | `remotion-best-practices` |
