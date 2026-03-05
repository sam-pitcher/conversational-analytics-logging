view: user_query_embeddings {
  derived_table: {
    datagroup_trigger: daily
    increment_key: "timestamp"
    sql:
      SELECT
        *
      FROM
        ML.GENERATE_EMBEDDING(
          MODEL @{embedding_model},
          (
            SELECT
              event_id,
              timestamp,
              user_query,
              user_query AS content
            FROM ${interaction_logs.SQL_TABLE_NAME}
            WHERE {% incrementcondition %} timestamp {% endincrementcondition %}
            AND user_query IS NOT NULL
          ),
          STRUCT(TRUE AS flatten_json_output)
        )
        ;;
  }

  dimension: event_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.event_id ;;
  }

  # The embedding is a large array of floats.
  # Usually hidden in Looker as it's used for backend math/clustering.
  dimension: embedding_vector {
    hidden: yes
    sql: ${TABLE}.text_embedding ;;
  }
}

view: user_query_clusters {
  derived_table: {
    sql:
    SELECT
      event_id,
      user_query,
      centroid_id AS cluster_id
    FROM
      ML.PREDICT(
        MODEL @{cluster_model},
        (SELECT event_id, user_query, ml_generate_embedding_result FROM ${user_query_embeddings.SQL_TABLE_NAME})
      )
    ;;
  }

  dimension: event_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.event_id ;;
  }

  dimension: cluster_id {
    type: number
    sql: ${TABLE}.cluster_id ;;
  }

}
