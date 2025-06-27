{{- define "gitops-html.configmapHash" -}}
{{- .Files.Get "templates/configmap.yaml" | sha256sum -}}
{{- end -}}