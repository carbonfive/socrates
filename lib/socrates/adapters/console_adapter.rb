class ConsoleAdapter
  CLIENT_ID = 'CONSOLE'

  def client_id_from_context(_context)
    CLIENT_ID
  end

  def send_message(message, _context)
    puts "\n@timesheet: #{message}"
  end
end
