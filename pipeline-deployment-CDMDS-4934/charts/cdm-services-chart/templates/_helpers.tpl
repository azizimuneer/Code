{{- define "abc_armis_connector.envVars" -}}
- secretRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_armis_connector.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_armis_connector.name }} 
{{- end }}

{{- define "abc_armis_connector.externalSecret.data" }}
{{- range .Values.abc_cdm_data_pipeline.abc_armis_connector.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "abc_armis_processor.envVars" -}}
- secretRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_armis_processor.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_armis_processor.name }} 
{{- end }}

{{- define "abc_armis_processor.externalSecret.data" }}
{{- range .Values.abc_cdm_data_pipeline.abc_armis_processor.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "abc_elastic_sink.envVars" -}}
- secretRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_elastic_sink.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_elastic_sink.name }}
{{- end }}

{{- define "abc_elastic_sink.externalSecret.data" }}
{{- range .Values.abc_cdm_data_pipeline.abc_elastic_sink.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}


{{- define "abc_quality_elastic_sink.envVars" -}}
- secretRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_quality_elastic_sink.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_quality_elastic_sink.name }}
{{- end }}

{{- define "abc_quality_elastic_sink.externalSecret.data" }}
{{- range .Values.abc_cdm_data_pipeline.abc_quality_elastic_sink.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "abc_cdm_processor.envVars" -}}
- secretRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_cdm_processor.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_cdm_processor.name }} 
{{- end }}

{{- define "abc_cdm_processor.externalSecret.data" }}
{{- range .Values.abc_cdm_data_pipeline.abc_cdm_processor.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "abc_quality_cdm_processor.envVars" -}}
- secretRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_quality_cdm_processor.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.abc_cdm_data_pipeline.abc_quality_cdm_processor.name }} 
{{- end }}

{{- define "abc_quality_cdm_processor.externalSecret.data" }}
{{- range .Values.abc_cdm_data_pipeline.abc_quality_cdm_processor.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}




{{- define "xyz_axonius_connector.envVars" -}}
- secretRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_axonius_connector.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_axonius_connector.name }} 
{{- end }}

{{- define "xyz_axonius_connector.externalSecret.data" }}
{{- range .Values.xyz_cdm_data_pipeline.xyz_axonius_connector.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "xyz_axonius_processor.envVars" -}}
- secretRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_axonius_processor.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_axonius_processor.name }} 
{{- end }}

{{- define "xyz_axonius_processor.externalSecret.data" }}
{{- range .Values.xyz_cdm_data_pipeline.xyz_axonius_processor.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "xyz_elastic_sink.envVars" -}}
- secretRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_elastic_sink.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_elastic_sink.name }}
{{- end }}

{{- define "xyz_elastic_sink.externalSecret.data" }}
{{- range .Values.xyz_cdm_data_pipeline.xyz_elastic_sink.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}


{{- define "xyz_quality_elastic_sink.envVars" -}}
- secretRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_quality_elastic_sink.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_quality_elastic_sink.name }}
{{- end }}

{{- define "xyz_quality_elastic_sink.externalSecret.data" }}
{{- range .Values.xyz_cdm_data_pipeline.xyz_quality_elastic_sink.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "xyz_cdm_processor.envVars" -}}
- secretRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_cdm_processor.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_cdm_processor.name }} 
{{- end }}

{{- define "xyz_cdm_processor.externalSecret.data" }}
{{- range .Values.xyz_cdm_data_pipeline.xyz_cdm_processor.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}

{{- define "xyz_quality_cdm_processor.envVars" -}}
- secretRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_quality_cdm_processor.externalSecret.target.name }}
- configMapRef:
    name: {{ .Values.xyz_cdm_data_pipeline.xyz_quality_cdm_processor.name }} 
{{- end }}

{{- define "xyz_quality_cdm_processor.externalSecret.data" }}
{{- range .Values.xyz_cdm_data_pipeline.xyz_quality_cdm_processor.externalSecret.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteRef.key }}
      property: {{ .remoteRef.property }}
{{- end }}
{{- end }}



{{- define "cdm_dictionary_connector.envVars" -}}
- configMapRef:
    name: {{ .Values.cdm_dictionary_connector.name }} 
{{- end }}