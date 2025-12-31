FROM chatwoot/chatwoot:v4.9.1

# Copiamos CSS a /public para servirlo como archivo estático
COPY custom.css /app/public/custom.css

# Inyectamos el <link> del CSS en el dashboard
RUN sed -i 's#</head>#  <link rel="stylesheet" href="/custom.css" />\n</head>#' /app/app/views/dashboard/index.html.erb || \
    sed -i 's#</head>#  <link rel="stylesheet" href="/custom.css" />\n</head>#' /app/views/dashboard/index.html.erb
