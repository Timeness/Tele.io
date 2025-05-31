(ql:quickload :dexador)
(ql:quickload :cl-json)

(defparameter *bot-token* "YOUR_BOT_TOKEN_HERE")
(defparameter *api-url* (concatenate 'string "https://api.telegram.org/bot" *bot-token*))
(defparameter *last-update-id* 0)
(defparameter *global-env* (make-hash-table))
(defparameter *local-env* (make-hash-table))

(defun send-request (endpoint data)
  (let ((url (concatenate 'string *api-url* "/" endpoint)))
    (cl-json:decode-json-from-string
     (dex:post url :content (cl-json:encode-json-to-string data)))))

(defun send-message (chat-id text)
  (send-request "sendMessage"
                `(("chat_id" . ,chat-id)
                  ("text" . ,text))))

(defun ban-user (chat-id user-id)
  (send-request "banChatMember"
                `(("chat_id" . ,chat-id)
                  ("user_id" . ,user-id))))

(defun eval-expression (expr env)
  (handler-case
      (let ((result (eval (read-from-string expr))))
        (format nil "~A" result))
    (error () "Error evaluating expression")))

(defun get-updates ()
  (let* ((data `(("offset" . ,(+ *last-update-id* 1))))
         (response (send-request "getUpdates" data))
         (updates (cdr (assoc :result response))))
    (when (cdr (assoc :ok response))
      (dolist (update updates)
        (setf *last-update-id* (cdr (assoc :update--id update)))
        (process-update update)))))

(defun process-update (update)
  (let ((message (cdr (assoc :message update))))
    (if (null message)
        (let ((new-members (cdr (assoc :new--chat--members update))))
          (when new-members
            (let ((chat-id (cdr (assoc :id (cdr (assoc :chat update))))))
              (dolist (member new-members)
                (let ((username (or (cdr (assoc :username member)) "User")))
                  (send-message chat-id (format nil "Welcome, ~A!" username)))))))
        (let* ((chat-id (cdr (assoc :id (cdr (assoc :chat message)))))
               (text (or (cdr (assoc :text message)) ""))
               (user-id (cdr (assoc :id (cdr (assoc :from message)))))
               (username (or (cdr (assoc :username (cdr (assoc :from message)))) "User")))
          (when (string-starts-with text "/")
            (handle-command chat-id user-id username text message))))))

(defun string-starts-with (str prefix)
  (and (>= (length str) (length prefix))
       (string= (subseq str 0 (length prefix)) prefix)))

(defun handle-command (chat-id user-id username text message)
  (let* ((parts (split-sequence:split-sequence #\Space text))
         (command (first parts))
         (args (rest parts)))
    (cond
     ((string= command "/help")
      (send-message chat-id "Commands:\n/help - Show this help\n/ban [id] - Ban user by ID or reply\n/id - Get user/chat ID\n/eval [expr] - Evaluate Lisp expression"))
     ((string= command "/ban")
      (if args
          (let ((target-user-id (parse-integer (first args) :junk-allowed t)))
            (if target-user-id
                (progn
                  (ban-user chat-id target-user-id)
                  (send-message chat-id (format nil "User ~A banned." target-user-id)))
                (send-message chat-id "Invalid user ID.")))
          (let ((reply-to (cdr (assoc :reply--to--message message))))
            (if (null reply-to)
                (send-message chat-id "Reply to a message or provide a user ID (/ban <id>).")
                (let ((target-user-id (cdr (assoc :id (cdr (assoc :from reply-to))))))
                  (ban-user chat-id target-user-id)
                  (send-message chat-id "User banned."))))))
     ((string= command "/id")
      (let ((reply-to (cdr (assoc :reply--to--message message))))
        (if reply-to
            (let ((target-user-id (cdr (assoc :id (cdr (assoc :from reply-to)))))
                  (target-username (or (cdr (assoc :username (cdr (assoc :from reply-to)))) "User")))
              (send-message chat-id
                            (format nil "Replied user: ~A~%User ID: ~A~%Chat ID: ~A"
                                    target-username target-user-id chat-id)))
            (send-message chat-id
                          (format nil "User: ~A~%User ID: ~A~%Chat ID: ~A"
                                  username user-id chat-id)))))
     ((string= command "/eval")
      (if (null args)
          (send-message chat-id "Provide an expression to evaluate (/eval <expression>).")
          (let* ((env-type (if (member (first args) '("global" "local") :test #'string=)
                              (if (string= (first args) "global") *global-env* *local-env*)
                              *local-env*))
                 (expr (if (member (first args) '("global" "local") :test #'string=)
                          (format nil "~{~A~^ ~}" (rest args))
                          (format nil "~{~A~^ ~}" args))))
            (let ((result (eval-expression expr env-type)))
              (send-message chat-id (format nil "Result: ~A" result)))))))))

(defun run ()
  (format t "Bot started...~%")
  (loop
    (get-updates)
    (sleep 0.5)))

(run)
