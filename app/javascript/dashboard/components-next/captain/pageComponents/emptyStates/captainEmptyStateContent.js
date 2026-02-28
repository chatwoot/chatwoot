import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const assistantsList = [
  {
    account_id: 2,
    config: { product_name: 'Маркетплейс KZ' },
    created_at: 1736033561,
    description:
      'Помогает отвечать клиентам по заказам, оплате в тенге и доставке по Казахстану.',
    id: 4,
    name: 'Alem Support AI',
  },
  {
    account_id: 3,
    config: { product_name: 'CRM для продаж' },
    created_at: 1736033562,
    description:
      'Автоматизирует follow-up по лидам из Алматы и Астаны, помогает держать воронку под контролем.',
    id: 5,
    name: 'CRM Ассистент KZ',
  },
  {
    account_id: 4,
    config: { product_name: 'Продажи и заявки' },
    created_at: 1736033563,
    description:
      'Подсказывает менеджерам, как быстрее закрывать заявки и не терять повторные продажи.',
    id: 6,
    name: 'Sales Bot Qazaq',
  },
  {
    account_id: 5,
    config: { product_name: 'Служба поддержки' },
    created_at: 1736033564,
    description:
      'Распределяет обращения по темам: доставка, возврат, оплата, и снижает нагрузку на операторов.',
    id: 7,
    name: 'Ticket Ассистент',
  },
  {
    account_id: 6,
    config: { product_name: 'Финансы и отчеты' },
    created_at: 1736033565,
    description:
      'Объясняет финансовые метрики и помогает собирать отчеты по продажам и возвратам.',
    id: 8,
    name: 'Finance Helper KZ',
  },
  {
    account_id: 8,
    config: { product_name: 'Команда и HR' },
    created_at: 1736033567,
    description:
      'Помогает в адаптации сотрудников, внутренней базе знаний и стандартных HR-ответах.',
    id: 10,
    name: 'HR Көмекші',
  },
];

export const documentsList = [
  {
    account_id: 1,
    assistant: { id: 1, name: 'Alem Support AI' },
    content:
      'Регламент обработки обращений: приоритеты, SLA и правила эскалации.',
    created_at: 1736143272,
    external_link: 'https://help.example.kz/support/sla-and-escalation',
    id: 3059,
    name: 'SLA и эскалации: регламент поддержки',
    status: 'available',
  },
  {
    account_id: 2,
    assistant: { id: 2, name: 'CRM Ассистент KZ' },
    content:
      'Скрипты продаж для операторов: как отвечать на частые вопросы клиентов.',
    created_at: 1736143273,
    external_link: 'https://help.example.kz/sales/operator-scripts',
    id: 3060,
    name: 'Скрипты ответов для операторов',
    status: 'available',
  },
  {
    account_id: 3,
    assistant: { id: 3, name: 'Sales Bot Qazaq' },
    content:
      'Политика доставки по Казахстану: сроки, тарифы и регионы покрытия.',
    created_at: 1736143274,
    external_link: 'https://help.example.kz/delivery/kazakhstan-regions',
    id: 3061,
    name: 'Доставка по Казахстану: сроки и тарифы',
    status: 'available',
  },
  {
    account_id: 4,
    assistant: { id: 4, name: 'Ticket Ассистент' },
    content: 'Условия возврата и обмена: стандартные кейсы и исключения.',
    created_at: 1736143275,
    external_link: 'https://help.example.kz/returns/policy',
    id: 3062,
    name: 'Возврат и обмен: политика компании',
    status: 'available',
  },
  {
    account_id: 5,
    assistant: { id: 5, name: 'Finance Helper KZ' },
    content: 'FAQ по оплате: Kaspi, карты Visa/Mastercard, счета для юрлиц.',
    created_at: 1736143276,
    external_link: 'https://help.example.kz/payments/payment-methods',
    id: 3063,
    name: 'Оплата заказов: методы и частые вопросы',
    status: 'available',
  },
  {
    account_id: 6,
    assistant: { id: 6, name: 'HR Көмекші' },
    content: 'Онбординг операторов: стандарты тона, время ответа и шаблоны.',
    created_at: 1736143277,
    external_link: 'https://help.example.kz/team/onboarding-support',
    id: 3064,
    name: 'Онбординг операторов поддержки',
    status: 'available',
  },
];

export const responsesList = [
  {
    account_id: 1,
    answer:
      'Канал мог отключиться из-за ограничений тарифа или если превышен лимит подключенных источников.',
    created_at: 1736283330,
    id: 87,
    question: 'Почему канал Messenger/Instagram отключился?',
    status: 'pending',
    assistant: {
      account_id: 1,
      config: { product_name: 'Маркетплейс KZ' },
      created_at: 1736033280,
      description:
        'Отвечает на общие технические вопросы и помогает с настройкой каналов.',
      id: 1,
      name: 'Alem Support AI',
    },
  },
  {
    account_id: 2,
    answer:
      'Откройте раздел "Интеграции", выберите WhatsApp и пройдите подключение номера через Meta.',
    created_at: 1736283340,
    id: 88,
    question: 'Как подключить WhatsApp Business?',
    assistant: {
      account_id: 2,
      config: { product_name: 'Служба поддержки' },
      created_at: 1736033281,
      description:
        'Помогает с интеграциями и первоначальной настройкой проекта.',
      id: 2,
      name: 'Ticket Ассистент',
    },
  },
  {
    account_id: 3,
    answer:
      'На странице входа нажмите "Забыли пароль?" и следуйте инструкции из письма.',
    created_at: 1736283350,
    id: 89,
    question: 'Как восстановить пароль сотрудника?',
    assistant: {
      account_id: 3,
      config: { product_name: 'Команда и HR' },
      created_at: 1736033282,
      description:
        'Закрывает вопросы по доступам и восстановлению учетных записей.',
      id: 3,
      name: 'HR Көмекші',
    },
  },
  {
    account_id: 4,
    answer:
      'Да, в настройках интерфейса можно переключить светлую и темную тему.',
    created_at: 1736283360,
    id: 90,
    question: 'Можно включить темную тему интерфейса?',
    assistant: {
      account_id: 4,
      config: { product_name: 'CRM для продаж' },
      created_at: 1736033283,
      description:
        'Помогает с вопросами по интерфейсу и личным настройкам операторов.',
      id: 4,
      name: 'CRM Ассистент KZ',
    },
  },
  {
    account_id: 5,
    answer:
      'Перейдите в "Настройки" -> "Команда" -> "Добавить участника", затем назначьте роль и источники.',
    created_at: 1736283370,
    id: 91,
    question: 'Как добавить нового оператора в команду?',
    assistant: {
      account_id: 5,
      config: { product_name: 'Команда и HR' },
      created_at: 1736033284,
      description:
        'Отвечает за админ-вопросы по ролям, доступам и структуре команды.',
      id: 5,
      name: 'HR Көмекші',
    },
  },
  {
    account_id: 6,
    answer:
      'Кампании позволяют отправлять адресные сообщения по сегментам клиентов, например отдельно по Алматы и Астане.',
    created_at: 1736283380,
    id: 92,
    question: 'Для чего нужны кампании в Chatwoot?',
    assistant: {
      account_id: 6,
      config: { product_name: 'Маркетинг и коммуникации' },
      created_at: 1736033285,
      description:
        'Специализируется на маркетинге, сегментах клиентов и массовых рассылках.',
      id: 6,
      name: 'Sales Bot Qazaq',
    },
  },
];

export const inboxes = [
  {
    id: 7,
    name: 'Поддержка по email',
    channel_type: INBOX_TYPES.EMAIL,
    email: 'support@example.kz',
  },
  {
    id: 1,
    name: 'Чат на сайте',
    channel_type: INBOX_TYPES.WEB,
  },
  {
    id: 2,
    name: 'Поддержка в Facebook',
    channel_type: INBOX_TYPES.FB,
  },
  {
    id: 5,
    name: 'SMS-рассылки',
    channel_type: INBOX_TYPES.TWILIO,
    messaging_service_sid: 'MGxxxxxx',
  },
  {
    id: 6,
    name: 'Поддержка в WhatsApp',
    channel_type: INBOX_TYPES.WHATSAPP,
    phone_number: '+77071234567',
  },
  {
    id: 8,
    name: 'Поддержка в Telegram',
    channel_type: INBOX_TYPES.TELEGRAM,
  },
  {
    id: 9,
    name: 'LINE поддержка',
    channel_type: INBOX_TYPES.LINE,
  },
  {
    id: 10,
    name: 'API-канал',
    channel_type: INBOX_TYPES.API,
  },
  {
    id: 11,
    name: 'Сервисные SMS',
    channel_type: INBOX_TYPES.SMS,
    phone_number: '+77017654321',
  },
];
