{{/* Define the secrets */}}
{{- define "authelia.secrets" -}}
{{- $autheliaprevious := lookup "v1" "Secret" .Release.Namespace "authelia-secrets" }}
{{- $oidckey := "" }}
{{- $oidcsecret := "" }}
{{- $jwtsecret := "" }}
{{- $sessionsecret := "" }}
{{- $encryptionkey := "" }}
enabled: true
data:
  {{- if $autheliaprevious }}
  SESSION_ENCRYPTION_KEY: {{ index $autheliaprevious.data "SESSION_ENCRYPTION_KEY"  }}
  JWT_TOKEN: {{ index $autheliaprevious.data "JWT_TOKEN"  }}
  {{- if ( hasKey $autheliaprevious.data "ENCRYPTION_KEY" ) }}
  ENCRYPTION_KEY: {{ index $autheliaprevious.data "ENCRYPTION_KEY"  }}
  {{- else }}
  {{- $encryptionkey := randAlphaNum 100 }}
  ENCRYPTION_KEY: {{ $encryptionkey }}
  {{- end }}
  {{- else }}
  {{- $jwtsecret := randAlphaNum 50 }}
  {{- $sessionsecret := randAlphaNum 50 }}
  {{- $encryptionkey := randAlphaNum 100 }}
  SESSION_ENCRYPTION_KEY: {{ $sessionsecret }}
  JWT_TOKEN: {{ $jwtsecret}}
  ENCRYPTION_KEY: {{ $encryptionkey }}
  {{- end }}

  {{- if .Values.authentication_backend.ldap.enabled }}
  LDAP_PASSWORD: {{ .Values.authentication_backend.ldap.plain_password }}
  {{- end }}

  {{- if and .Values.notifier.smtp.enabled .Values.notifier.smtp.plain_password }}
  SMTP_PASSWORD: {{ .Values.notifier.smtp.plain_password }}
  {{- end }}

  {{- if .Values.duo_api.enabled }}
  DUO_API_KEY: {{ .Values.duo_api.plain_api_key }}
  {{- end }}

  STORAGE_PASSWORD: {{ $.Values.cnpg.main.creds.password | trimAll "\"" }}

  REDIS_PASSWORD: {{ .Values.redis.redisPassword | trimAll "\"" }}
  {{- if .Values.redisProvider.high_availability.enabled}}
  REDIS_SENTINEL_PASSWORD: {{ .Values.redis.sentinelPassword | trimAll "\"" }}
  {{- end }}

  {{- if $autheliaprevious }}
  {{- if and ( hasKey $autheliaprevious.data "OIDC_PRIVATE_KEY" ) ( hasKey $autheliaprevious.data "OIDC_HMAC_SECRET" ) }}
  OIDC_PRIVATE_KEY: {{ index $autheliaprevious.data "OIDC_PRIVATE_KEY"  }}
  OIDC_HMAC_SECRET: {{ index $autheliaprevious.data "OIDC_HMAC_SECRET" }}
  {{- else }}
  {{- $oidckey := genPrivateKey "rsa"   }}
  {{- $oidcsecret := randAlphaNum 32 }}
  OIDC_PRIVATE_KEY: {{ $oidckey }}
  OIDC_HMAC_SECRET: {{ $oidcsecret }}
  {{- end }}
  {{- end }}
{{- end -}}
