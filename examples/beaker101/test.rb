hosts.each do |h|
  on h, "echo hello"
end
