{{/*
Expand the name of the chart.
*/}}
{{- define "chatwoot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chatwoot.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chatwoot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chatwoot.labels" -}}
helm.sh/chart: {{ include "chatwoot.chart" . }}
{{ include "chatwoot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chatwoot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chatwoot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chatwoot.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chatwoot.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "chatwoot.postgresql.fullname" -}}
{{- if .Values.postgresql.fullnameOverride -}}
{{- .Values.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.postgresql.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "chatwoot-postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "chatwoot.redis.fullname" -}}
{{- if .Values.redis.fullnameOverride -}}
{{- .Values.redis.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.redis.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "chatwoot-redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Set postgres host
*/}}
{{- define "chatwoot.postgresql.host" -}}
{{- if .Values.postgresql.enabled -}}
{{- template "chatwoot.postgresql.fullname" . -}}
{{- else -}}
{{- .Values.postgresql.postgresqlHost -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres secret
*/}}
{{- define "chatwoot.postgresql.secret" -}}
{{- if .Values.postgresql.enabled -}}
{{- template "chatwoot.postgresql.fullname" . -}}
{{- else -}}
{{- template "chatwoot.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres secretKey
*/}}
{{- define "chatwoot.postgresql.secretKey" -}}
{{- if .Values.postgresql.enabled -}}
"postgresql-password"
{{- else -}}
{{- default "postgresql-password" .Values.postgresql.auth.secretKeys.adminPasswordKey | quote -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres port
*/}}
{{- define "chatwoot.postgresql.port" -}}
{{- if .Values.postgresql.enabled -}}
    5432
{{- else -}}
{{- default 5432 .Values.postgresql.postgresqlPort -}}
{{- end -}}
{{- end -}}

{{/*
Set redis host
*/}}
{{- define "chatwoot.redis.host" -}}
{{- if .Values.redis.enabled -}}
{{- template "chatwoot.redis.fullname" . -}}-master
{{- else -}}
{{- .Values.redis.host }}
{{- end -}}
{{- end -}}

{{/*
Set redis secret
*/}}
{{- define "chatwoot.redis.secret" -}}
{{- if .Values.redis.enabled -}}
{{- template "chatwoot.redis.fullname" . -}}
{{- else -}}
{{- template "chatwoot.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set redis secretKey
*/}}
{{- define "chatwoot.redis.secretKey" -}}
{{- if .Values.redis.enabled -}}
"redis-password"
{{- else -}}
{{- default "redis-password" .Values.redis.auth.existingSecretKey | quote -}}
{{- end -}}
{{- end -}}

{{/*
Set redis port
*/}}
{{- define "chatwoot.redis.port" -}}
{{- if .Values.redis.enabled -}}
    6379
{{- else -}}
{{- default 6379 .Values.redis.port -}}
{{- end -}}
{{- end -}}

{{/*
Set redis password
*/}}
{{- define "chatwoot.redis.password" -}}
{{- if .Values.redis.enabled -}}
{{- default "redis" .Values.redis.auth.password -}}
{{- else -}}
{{- default "redis" .Values.redis.password -}}
{{- end -}}
{{- end -}}

{{/*
Set redis URL
*/}}
{{- define "chatwoot.redis.url" -}}
{{- if .Values.redis.enabled -}}
    redis://:$(REDIS_PASSWORD)@{{ template "chatwoot.redis.host" . }}:{{ template "chatwoot.redis.port" . }}
{{- else if .Values.env.REDIS_TLS -}}
    rediss://:$(REDIS_PASSWORD)@{{ .Values.redis.host }}:{{ .Values.redis.port }}
{{- else -}}
    redis://:$(REDIS_PASSWORD)@{{ .Values.redis.host }}:{{ .Values.redis.port }}
{{- end -}}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "common.tplvalues.render" -}}
{{- if typeIs "string" .value }}
{{- tpl .value .context }}
{{- else }}
{{- tpl (.value | toYaml) .context }}
{{- end }}
{{- end -}}
