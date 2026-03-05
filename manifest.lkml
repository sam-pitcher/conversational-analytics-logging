project_name: "conversational_analytics_logging"

application: conversation_analytics_app {
  label: "Conversation Analytics"
  # This points Looker to your local Vite dev server
  # url: "https://localhost:8080/bundle.js"

  file: "bundle.js"

  entitlements: {
    # Allows the extension to make Looker API calls on behalf of the user
    core_api_methods: ["run_inline_query", "me", "all_lookml_models"]

    # Allows interfacing with external backends securely
    use_embeds: yes
    use_form_submit: yes
    use_iframes: yes
    external_api_urls: ["http://127.0.0.1:8000", "http://localhost:8000", "http://127.0.0.1:8001", "http://localhost:8001"]
  }
}

constant: embedding_model {
  value: "`conversation_logs.embedding_model`"
}

constant: cluster_model {
  value: "`conversation_logs.question_clusters`"
}
