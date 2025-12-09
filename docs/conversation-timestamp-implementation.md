# Implementação do Formato de Horário de Conversas

## Objetivo

Alterar a exibição do horário nas conversas do Chatwoot para mostrar informações mais específicas sobre a última atividade, substituindo o formato relativo (ex: "3h") por formatos mais úteis baseados no tempo decorrido.

## Comportamento Implementado

A exibição do horário da última atividade agora segue estas regras:

- **Menos de 24 horas**: Exibe o horário no formato `HH:mm` (ex: 19:32)
- **Exatamente 1 dia**: Exibe o texto "Ontem"
- **2 ou mais dias**: Exibe a data completa no formato `dd/MM/yyyy` (ex: 30/11/2025)

## Arquivos Modificados

### 1. `app/javascript/shared/helpers/timeHelper.js`

**Mudanças realizadas:**
- Adicionada importação de `differenceInHours` do `date-fns`
- Criada nova função `conversationTimestamp()`

**Nova função:**

```javascript
export const conversationTimestamp = time => {
  const now = new Date();
  const unixTime = fromUnixTime(time);
  const hoursDifference = differenceInHours(now, unixTime);
  const daysDifference = differenceInDays(now, unixTime);

  // Less than 24 hours: show time (HH:mm)
  if (hoursDifference < 24 && daysDifference === 0) {
    return format(unixTime, 'HH:mm');
  }

  // Between 24-48 hours (1 day ago): show "Ontem"
  if (daysDifference === 1) {
    return 'Ontem';
  }

  // 2 or more days ago: show date (dd/MM/yyyy)
  return format(unixTime, 'dd/MM/yyyy');
};
```

**Lógica:**
1. Calcula a diferença em horas e dias entre o timestamp fornecido e o momento atual
2. Se for menos de 24 horas E for do mesmo dia (diferença de 0 dias), retorna o horário
3. Se for exatamente 1 dia atrás, retorna "Ontem"
4. Se for 2 ou mais dias, retorna a data formatada

### 2. `app/javascript/dashboard/i18n/locale/en/chatlist.json`

**Mudanças realizadas:**
- Adicionada chave de tradução para "Yesterday" no objeto `CHAT_TIME_STAMP`

```json
"CHAT_TIME_STAMP": {
  "CREATED": {
    "LATEST": "Created",
    "OLDEST": "Created at:"
  },
  "LAST_ACTIVITY": {
    "NOT_ACTIVE": "Last activity:",
    "ACTIVE": "Last activity"
  },
  "YESTERDAY": "Yesterday"
}
```

**Nota:** Conforme as diretrizes do projeto, apenas o arquivo `en.json` foi modificado. Traduções para outros idiomas são gerenciadas pela comunidade.

### 3. `app/javascript/dashboard/components/ui/TimeAgo.vue`

**Mudanças realizadas:**
- Substituída importação de `dynamicTime` e `shortTimestamp` por `conversationTimestamp`
- Atualizados todos os lugares onde a função de formatação de tempo é chamada
- Modificado o template para exibir apenas a última atividade (removido o horário de criação)

**Antes:**
```javascript
import {
  dynamicTime,
  dateFormat,
  shortTimestamp,
} from 'shared/helpers/timeHelper';

// ...

computed: {
  lastActivityTime() {
    return shortTimestamp(this.lastActivityAtTimeAgo);
  },
  createdAtTime() {
    return shortTimestamp(this.createdAtTimeAgo);
  },
}
```

**Depois:**
```javascript
import {
  conversationTimestamp,
  dateFormat,
} from 'shared/helpers/timeHelper';

// ...

computed: {
  lastActivityTime() {
    return this.lastActivityAtTimeAgo;
  },
  createdAtTime() {
    return this.createdAtTimeAgo;
  },
}
```

**Template - Antes:**
```vue
<span>{{ `${createdAtTime} • ${lastActivityTime}` }}</span>
```

**Template - Depois:**
```vue
<span>{{ lastActivityTime }}</span>
```

### 4. `app/javascript/dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue`

**Mudanças realizadas:**
- Substituída importação de `dynamicTime` e `shortTimestamp` por `conversationTimestamp`
- Simplificado o computed property `lastActivityAt` para usar diretamente a nova função

**Antes:**
```javascript
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';

// ...

const lastActivityAt = computed(() => {
  const timestamp = props.conversation?.timestamp;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});
```

**Depois:**
```javascript
import { conversationTimestamp } from 'shared/helpers/timeHelper';

// ...

const lastActivityAt = computed(() => {
  const timestamp = props.conversation?.timestamp;
  return timestamp ? conversationTimestamp(timestamp) : '';
});
```

## Componentes Afetados

Esta alteração impacta a exibição de horário nos seguintes componentes:

1. **TimeAgo.vue**: Componente legado usado nas listas de conversas antigas
2. **ConversationCard.vue**: Componente novo (components-next) usado nas listas de conversas modernas

## Benefícios da Implementação

1. **Clareza**: Usuários veem informações mais específicas sobre quando foi a última atividade
2. **Contexto**: O formato varia de acordo com a relevância temporal
3. **Consistência**: Ambos os componentes (legado e novo) usam a mesma lógica
4. **Manutenibilidade**: Lógica centralizada em uma única função helper
5. **Internacionalização**: Preparado para suportar traduções (chave YESTERDAY adicionada)

## Considerações Técnicas

### Atualização Automática
O componente `TimeAgo.vue` possui um timer que atualiza os horários automaticamente:
- A cada minuto (se < 1 hora)
- A cada hora (se entre 1 hora e 1 dia)
- A cada dia (se > 1 dia)

Isso garante que o formato mude automaticamente (ex: de "23:59" para "Ontem" à meia-noite).

### Performance
- Utiliza funções nativas do `date-fns` para cálculos de data
- Sem chamadas de API ou processamento pesado
- Cálculos feitos apenas quando necessário (computed properties)

### Compatibilidade
- Compatível com timestamps Unix em segundos (formato usado pelo Chatwoot)
- Funciona com diferentes timezones (usa horário local do navegador)

## Testes Recomendados

Para validar a implementação, teste os seguintes cenários:

1. **Mensagem enviada há poucos minutos**: Deve exibir horário (ex: 14:30)
2. **Mensagem enviada ontem**: Deve exibir "Ontem"
3. **Mensagem enviada há 3 dias**: Deve exibir data (ex: 29/11/2025)
4. **Transição de dia**: Aguarde a meia-noite para verificar se atualiza automaticamente
5. **Diferentes timezones**: Teste em diferentes configurações de timezone do navegador

## Futuras Melhorias

Possíveis melhorias futuras para esta implementação:

1. **Internacionalização completa**: Usar `i18n` dentro da função helper para traduzir "Ontem"
2. **Formatos customizáveis**: Permitir que administradores configurem os formatos de data/hora
3. **Tooltip com informações completas**: Manter um tooltip com data/hora exata e completa
4. **Formato relativo para tooltip**: Manter "há 3 horas" no tooltip para contexto adicional

