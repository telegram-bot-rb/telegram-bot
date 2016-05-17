# 0.7.0 Unreleased

- New Bot API methods.
- Helpers for inline keyboards, support for callback_query (with contextual actions).
- Changed action methods signature
  - `#inline_query(payload) -> #inline_query(query, offset)`
  - `#chosen_inline_result(payload)` -> `#chosen_inline_result(result_id, query)`

# 0.6.0

- StaleChat error.
- Encode arrays as json in request body.

# 0.5.0

- MessageContext.
- Running controller action without update.
- Client.wrap supports symbols.
- Improved testing utils: ability to process multiple updates on same controller instance,
  stubbing all clients in application.
