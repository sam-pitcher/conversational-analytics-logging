view: status {
  derived_table: {
    datagroup_trigger: daily
    increment_key: "timestamp"
    increment_offset: 1
    sql: SELECT
        event_id,
        timestamp,
        content,
        user_query,
        -- Extracts the classification directly
        JSON_VALUE(ml_generate_text_result, '$.candidates[0].content.parts[0].text') AS status
      FROM
        ML.GENERATE_TEXT(
          MODEL `conversation_logs.gemini_2_5_flash`,
          (
            SELECT
              event_id,
              timestamp,
              content,
              user_query,
              CONCAT(
                'Analyze this conversational agent log. Classify it into exactly one of these categories: ',
                'MISSING_DATA: If the agent says there are no values or access to a specific table. ',
                'INCORRECT_DATA_DOMAIN: Agent has replied that the question is not related to this data. ',
                'MISSING_FIELD: If the agent says it lacks a field or column. The the fields needed to calculate the requested measure. ',
                'DISAMBIGUATION: If the agent asks for clarification or is confused between multiple options. ',
                'SUCCESS: If the agent successfully answered or is processing a query. ',
                'ERROR: For hallucinations or "field not found" messages. ',
                'Return ONLY the category name.',
                'Question user asked: ', user_query,
                'Content to analyze: ', content
              ) AS prompt
            FROM
              ${interaction_logs.SQL_TABLE_NAME}
            WHERE {% incrementcondition %} timestamp {%  endincrementcondition %}
          ),
          STRUCT(
            0.1 AS temperature,
            20 AS max_output_tokens
          )
        ) ;;
  }

  # embeddings on user input querys. use this to upgrade golden queries.

  dimension: event_id {
    type: string
    sql: ${TABLE}.event_id ;;
  }

  dimension_group: timestamp {
    type: time
    sql: ${TABLE}.timestamp ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

}

view: status_missing_field {
  derived_table: {
    datagroup_trigger: daily
    increment_key: "timestamp"
    increment_offset: 1
    sql: SELECT
        event_id,
        timestamp,
        content,
        user_query,
        status,
        -- Extracts the classification directly
        JSON_VALUE(ml_generate_text_result, '$.candidates[0].content.parts[0].text') AS missing_field
      FROM
        ML.GENERATE_TEXT(
          MODEL `conversation_logs.gemini_2_5_flash`,
          (
            SELECT
              event_id,
              timestamp,
              content,
              user_query,
              status,
              CONCAT(
                'Analyze this conversational agent log.'
                'It has been flagged that the user asked a question, but the required field doesnt exist.',
                'Question user asked: ', user_query,
                'Content to analyze: ', content,
                'Return ONLY the name of the missing field.'
              ) AS prompt
            FROM
              ${status.SQL_TABLE_NAME}
            WHERE {% incrementcondition %} timestamp {%  endincrementcondition %}
            AND status = 'MISSING_FIELD'
          ),
          STRUCT(
            0.1 AS temperature,
            20 AS max_output_tokens
          )
        ) ;;
  }

  dimension: event_id {
    type: string
    sql: ${TABLE}.event_id ;;
  }

  dimension_group: timestamp {
    type: time
    sql: ${TABLE}.timestamp ;;
  }

  dimension: missing_field {
    type: string
    sql: ${TABLE}.missing_field ;;
  }

}
