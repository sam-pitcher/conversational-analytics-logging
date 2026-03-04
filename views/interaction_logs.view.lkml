view: interaction_logs {
  # sql_table_name: `sampitcher-playground.conversation_logs.interaction_logs` ;;
  derived_table: {
    sql:
    SELECT
    -- Select all original columns
    timestamp,
    conversation_id,
    message_id,
    event_id,
    user_query,
    agent_id,
    interaction_type,
    content,
    summary,
    duration,
    part_duration,
    total_duration,
    raw_json,

      -- Extract common fields from JSON
      JSON_VALUE(raw_json, '$.timestamp') AS json_event_time,
      JSON_VALUE(raw_json, '$.systemMessage.text.textType') AS text_type,

      -- Extract the 'parts' array as a JSON string
      JSON_QUERY(raw_json, '$.systemMessage.text.parts') AS message_parts,

      -- Extract specific technical signatures or results
      JSON_VALUE(raw_json, '$.systemMessage.text.thoughtSignature') AS thought_signature,

      -- Extract complex objects (Schema, Data, Chart)
      JSON_QUERY(raw_json, '$.systemMessage.schema') AS schema_payload,
      JSON_QUERY(raw_json, '$.systemMessage.data') AS data_payload,
      JSON_QUERY(raw_json, '$.systemMessage.chart') AS chart_payload,

      JSON_VALUE(raw_json, '$.systemMessage.text.textType') AS json_text_type,

      -- 3. Extract Looker Context (Model and Explore)
      JSON_VALUE(raw_json, '$.systemMessage.schema.result.datasources[0].lookerExploreReference.lookmlModel') AS looker_model,
      JSON_VALUE(raw_json, '$.systemMessage.schema.result.datasources[0].lookerExploreReference.explore') AS looker_explore,
      JSON_VALUE(raw_json, '$.systemMessage.schema.result.datasources[0].lookerExploreReference.lookerInstanceUri') AS looker_instance_uri,

      -- 4. Extract SQL and Data Results
      JSON_VALUE(raw_json, '$.systemMessage.data.generatedSql') AS generated_sql,
      -- Keeps the data as a JSON string so Looker can handle it or you can parse it later
      JSON_QUERY(raw_json, '$.systemMessage.data.result.data') AS query_data_result,

      -- 5. Extract Chart Info
      JSON_VALUE(raw_json, '$.systemMessage.chart.result.vegaConfig.title') AS chart_title

      FROM
      `conversation_logs.interaction_logs`

      ;;
  }

  # --- Standard Dimensions ---

  dimension: message_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.message_id ;;
  }

  dimension: user_query {
    type: string
    sql: ${TABLE}.user_query ;;
  }

  dimension: event_id {
    type: string
    sql: ${TABLE}.event_id ;;
  }

  dimension: conversation_id {
    type: string
    sql: ${TABLE}.conversation_id ;;
  }

  dimension: agent_id {
    type: string
    sql: ${TABLE}.agent_id ;;
  }

  dimension: interaction_type {
    type: string
    sql: ${TABLE}.interaction_type ;;
  }

  dimension: content {
    type: string
    sql: ${TABLE}.content ;;
  }

  dimension: summary {
    type: string
    sql: ${TABLE}.summary ;;
  }

  # --- Time Dimensions ---

  dimension_group: interaction_timestamp {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.timestamp ;;
  }

  dimension_group: json_event_time {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.json_event_time ;;
  }

  # --- Numeric Dimensions ---

  dimension: part_duration {
    hidden: yes
    type: number
    sql: ${TABLE}.part_duration ;;
  }

  dimension: final_message_response_duration {
    hidden: yes
    type: number
    sql: ${TABLE}.total_duration ;;
  }

  # --- JSON Extracts (BigQuery Specific) ---

  dimension: raw_json {
    group_label: "JSON Metadata"
    type: string
    sql: ${TABLE}.raw_json ;;
  }

  dimension: json_text_type {
    group_label: "JSON Metadata"
    type: string
    sql: JSON_VALUE(${TABLE}.raw_json, '$.systemMessage.text.textType') ;;
  }

  dimension: json_thought_signature {
    group_label: "JSON Metadata"
    type: string
    sql: JSON_VALUE(${TABLE}.raw_json, '$.systemMessage.text.thoughtSignature') ;;
  }

  dimension: json_event_timestamp {
    group_label: "JSON Metadata"
    type: string
    sql: JSON_VALUE(${TABLE}.raw_json, '$.timestamp') ;;
  }

  # Extracts the first part of the message array
  dimension: first_message_part {
    group_label: "JSON Metadata"
    type: string
    sql: JSON_VALUE(${TABLE}.raw_json, '$.systemMessage.text.parts[0]') ;;
  }

  dimension_group: json_event {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.chart_title ;;
  }

  dimension: text_type {
    type: string
    sql: ${TABLE}.text_type ;;
  }

  dimension: thought_signature {
    type: string
    sql: ${TABLE}.thought_signature ;;
  }

  dimension: message_parts {
    type: string
    sql: ${TABLE}.message_parts ;;
  }

  dimension: schema_payload {
    group_label: "Payloads"
    type: string
    sql: ${TABLE}.schema_payload ;;
  }

  dimension: data_payload {
    group_label: "Payloads"
    type: string
    sql: ${TABLE}.data_payload ;;
  }

  dimension: chart_payload {
    group_label: "Payloads"
    type: string
    sql: ${TABLE}.chart_payload ;;
  }

  dimension: looker_model {
    group_label: "Looker Context"
    type: string
    sql: ${TABLE}.looker_model ;;
  }

  dimension: looker_explore {
    group_label: "Looker Context"
    type: string
    sql: ${TABLE}.looker_explore ;;
  }

  dimension: looker_instance_uri {
    group_label: "Looker Context"
    type: string
    sql: ${TABLE}.looker_instance_uri ;;
  }

  dimension: generated_sql {
    group_label: "Query Details"
    type: string
    sql: ${TABLE}.generated_sql ;;
  }

  dimension: query_data_result {
    group_label: "Query Details"
    type: string
    sql: ${TABLE}.query_data_result ;;
  }

  dimension: chart_title {
    group_label: "Query Details"
    type: string
    sql: ${TABLE}.chart_title ;;
  }

  # --- Measures ---

  measure: conversation_count {
    type: count_distinct
    sql: ${conversation_id} ;;
  }

  measure: message_count {
    type: count_distinct
    sql: ${message_id} ;;
  }

  measure: interaction_count {
    type: count
  }

  measure: interaction_duration {
    group_label: "Interaction Duration"
    type: sum
    sql: ${part_duration} ;;
  }

  measure: average_interaction_duration {
    group_label: "Interaction Duration"
    type: average
    sql: ${part_duration} ;;
  }

  measure: max_interaction_duration {
    group_label: "Interaction Duration"
    type: max
    sql: ${part_duration} ;;
  }

  measure: min_interaction_duration {
    group_label: "Interaction Duration"
    type: min
    sql: ${part_duration} ;;
  }

  measure: max_final_message_response_duration {
    type: max
    sql: ${final_message_response_duration} ;;
  }

  measure: total_final_message_response_duration {
    type: sum
    sql: ${final_message_response_duration} ;;
  }

}
