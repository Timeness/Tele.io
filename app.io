System ifErrorRaise
Socket := Object clone do(
  post := method(url, data,
    writeln("POST ", url, " with ", data)
    "{\"ok\": true, \"result\": []}"
  )
)

TelegramBot := Object clone do(
  token := "YOUR_BOT_TOKEN_HERE"
  apiUrl := "https://api.telegram.org/bot" .. token
  lastUpdateId := 0
  globalEnv := Map clone
  localEnv := Map clone

  sendRequest := method(endpoint, data,
    url := apiUrl .. "/" .. endpoint
    response := Socket post(url, data asJSON)
    JSON parse(response)
  )

  sendMessage := method(chatId, text,
    data := Map clone
    data atPut("chat_id", chatId)
    data atPut("text", text)
    sendRequest("sendMessage", data)
  )

  banUser := method(chatId, userId,
    data := Map clone
    data atPut("chat_id", chatId)
    data atPut("user_id", userId)
    sendRequest("banChatMember", data)
  )

  evalExpression := method(expr, env,
    try(
      result := doString(expr, env)
      return result asString
    ) catch(Exception,
      return "Error evaluating expression"
    )
  )

  getUpdates := method(
    data := Map clone
    data atPut("offset", lastUpdateId + 1)
    response := sendRequest("getUpdates", data)
    if(response at("ok"),
      updates := response at("result")
      updates foreach(update,
        lastUpdateId = update at("update_id")
        processUpdate(update)
      )
    )
  )

  processUpdate := method(update,
    message := update at("message")
    if(message isNil,
      newMembers := update at("new_chat_members")
      if(newMembers,
        chatId := update at("chat") at("id")
        newMembers foreach(member,
          username := member at("username") ifNilEval("User")
          sendMessage(chatId, "Welcome, " .. username .. "!")
        )
      )
      return
    )

    chatId := message at("chat") at("id")
    text := message at("text") ifNilEval("")
    userId := message at("from") at("id")
    username := message at("from") at("username") ifNilEval("User")

    if(text beginsWith("/"),
      handleCommand(chatId, userId, username, text, message)
    )
  )

  handleCommand := method(chatId, userId, username, text, message,
    parts := text split
    command := parts at(0)
    args := parts slice(1)

    if(command == "/start",
      sendMessage(chatId, "Modern group management bot. Use /help for commands.")
    )
    if(command == "/help",
      sendMessage(chatId, "Commands:\n/start - Start bot\n/help - Show help\n/ban [id] - Ban user by ID or reply\n/id - Get user/chat ID\n/eval [expr] - Evaluate expression")
    )
    if(command == "/ban",
      if(args size > 0,
        targetUserId := args at(0) asNumber
        if(targetUserId isNan,
          sendMessage(chatId, "Invalid user ID.")
          return
        )
        banUser(chatId, targetUserId)
        sendMessage(chatId, "User " .. targetUserId .. " banned.")
        return
      )
      replyTo := message at("reply_to_message")
      if(replyTo isNil,
        sendMessage(chatId, "Reply to a message or provide a user ID (/ban <id>).")
        return
      )
      targetUserId := replyTo at("from") at("id")
      banUser(chatId, targetUserId)
      sendMessage(chatId, "User banned.")
    )
    if(command == "/id",
      replyTo := message at("reply_to_message")
      if(replyTo,
        targetUserId := replyTo at("from") at("id")
        targetUsername := replyTo at("from") at("username") ifNilEval("User")
        sendMessage(chatId, "Replied user: " .. targetUsername .. "\nUser ID: " .. targetUserId .. "\nChat ID: " .. chatId)
        return
      )
      sendMessage(chatId, "User: " .. username .. "\nUser ID: " .. userId .. "\nChat ID: " .. chatId)
    )
    if(command == "/eval",
      if(args size == 0,
        sendMessage(chatId, "Provide an expression to evaluate (/eval <expression>).")
        return
      )
      expr := args join(" ")
      envType := if(args at(0) == "global", globalEnv, localEnv)
      if(args at(0) == "global" or args at(0) == "local", expr = args slice(1) join(" "))
      result := evalExpression(expr, envType)
      sendMessage(chatId, "Result: " .. result)
    )
  )

  run := method(
    writeln("Bot started...")
    loop(
      getUpdates
      System sleep(0.5)
    )
  )
)

bot := TelegramBot clone
bot run
