using FTPClient
using Base.Test

ftp_init()

###############################################################################
# Non-persistent connection tests, passive mode
###############################################################################

options = RequestOptions(ssl=false, active_mode=false, username=user, passwd=pswd, hostname=host)
println("\nTest non-persistent connection with passive mode:\n")

# test 1, download file from server
resp = ftp_get(file_name, options)
@test resp.code == 226
println("\nTest 1 passed.\n$resp")
# rm(file_name)

# test 2, upload file to server
file = open(upload_file)
resp = ftp_put("test_upload.txt", file, options)
@test resp.code ==226
println("\nTest 2 passed.\n$resp")
close(file)

# test 3, pass command to server
resp = ftp_command("PWD", options)
@test resp.code == 257
println("\nTest 3 passed.\n$resp")

# ###############################################################################
# Non-persistent connection tests, active mode
###############################################################################

options = RequestOptions(ssl=false, active_mode=true, username=user, passwd=pswd, hostname=host)
println("\nTest non-persistent connection with active mode:\n")

# test 4, download file from server
resp = ftp_get(file_name, options)
@test resp.code == 226
println("\nTest 4 passed.\n$resp")
# rm(file_name)

# test 5, upload file to server
file = open(upload_file)
resp = ftp_put("test_upload.txt", file, options)
@test resp.code ==226
println("\nTest 5 passed.\n$resp")
close(file)

# test 6, pass command to server
resp = ftp_command("PWD", options)
@test resp.code == 257
println("\nTest 6 passed.\n$resp")

###############################################################################
# Persistent connection tests, passive mode
###############################################################################

options = RequestOptions(ssl=false, active_mode=false, username=user, passwd=pswd, hostname=host)
println("\nTest persistent connection with passive mode:\n")

# test 7, establish connection
ctxt, resp = ftp_connect(options)
@test resp.code == 226
println("\nTest 7 passed.\n$(resp)")

# test 8, pass command to server
resp = ftp_command(ctxt, "PWD")
@test resp.code == 257
println("\nTest 8 passed.\n$(resp)")

# test 9, download file from server
resp = ftp_get(ctxt, file_name)
@test resp.code == 226
println("\nTest 9 passed.\n$(resp)")
# rm(file_name)

# test 10, upload file to server
file = open(upload_file)
resp = ftp_put(ctxt, "test_upload.txt", file)
@test resp.code ==226
println("\nTest 10 passed.\n$(resp)")

ftp_close_connection(ctxt)
close(file)

###############################################################################
# Persistent connection tests, active mode
###############################################################################

options = RequestOptions(ssl=false, active_mode=true, username=user, passwd=pswd, hostname=host)
println("\nTest persistent connection with active mode:\n")

# test 11, establish connection
ctxt, resp = ftp_connect(options)
@test resp.code == 226
println("\nTest 11 passed.\n$(resp)")

# test 12, pass command to server
resp = ftp_command(ctxt, "PWD")
@test resp.code == 257
println("\nTest 12 passed.\n$(resp)")

# test 13, download file from server
resp = ftp_get(ctxt, file_name)
@test resp.code == 226
println("\nTest 13 passed.\n$(resp)")
# rm(file_name)

# test 14, upload file to server
file = open(upload_file)
resp = ftp_put(ctxt, "test_upload.txt", file)
@test resp.code ==226
println("\nTest 14 passed.\n$(resp)")

ftp_close_connection(ctxt)
close(file)


facts("Non-ssl tests") do

save_file = "test_file_save_path.txt"
save_path = pwd() * "/" * save_file

context("download a file to a specific path") do

    resp = ftp_get(file_name, options, save_path)
    @fact resp.code --> 226
    @fact isfile(save_file) --> true
    file = open(save_file)
    @fact readall(file) --> file_contents
    close(file)
    rm(save_file)

end

end

ftp_cleanup()

println("FTPC non-ssl tests passed.\n\n")