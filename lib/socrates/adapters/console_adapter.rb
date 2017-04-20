class ConsoleAdapter
  CLIENT_ID = "CONSOLE"

  def initialize(name: "@socrates")
    @name = name
  end

  def client_id_from_context(_context)
    CLIENT_ID
  end

  def send_message(message, *)
    puts "\n#{colorize(@name, "32;1")}: #{message}"
  end

  def send_direct_message(message, user, *)
    name =
      if user.respond_to?(:name)
        user.name
      elsif user.respond_to?(:id)
        user.id
      else
        user
      end

    puts "\n[DM] #{colorize(name, "34;1")}: #{message}"
  end

  private

  def colorize(str, color_code)
    "\e[#{color_code}m#{str}\e[0m"
  end
end
