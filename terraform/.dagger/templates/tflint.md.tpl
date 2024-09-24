### `tflint`

{{- range $i, $issue := .issues }}
> [!{{ $issue.rule.severity }}]
> **{{ $issue.message }}**
> https://github.com/kid/home-infra/blob/f445eb84ce2483e46f6661939b2c84b7b01b3317/{{ $issue.range.filename }}#L{{ $issue.range.start.line }}-L{{ $issue.range.end.line }}
> {{ $issue.rule.link }}
{{ end }}
