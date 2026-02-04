{{- define "nextjs-app.name" -}}
nextjs-app
{{- end -}}

{{- define "nextjs-app.fullname" -}}
{{- include "nextjs-app.name" . -}}
{{- end -}}
