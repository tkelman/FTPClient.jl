type FTP
    ctxt::ConnContext

    function FTP(;host="", implt=false, ssl=false, ver_peer=true, act_mode=false, user="", pswd="", binary_mode=true)
        options = RequestOptions(implicit=implt, ssl=ssl,
                    verify_peer=ver_peer, active_mode=act_mode,
                    username=user, passwd=pswd, hostname=host, binary_mode=binary_mode)

        ctxt = nothing
        try
            ctxt, resp = ftp_connect(options)
        catch err
            if(isa(err, FTPClientError))
                err.msg = "Failed to connect."
            end
            rethrow()
        end

        new(ctxt)
    end
end


function show(io::IO, ftp::FTP)
    o = ftp.ctxt.options
    println(io, "Host:      $(ftp.ctxt.url)")
    println(io, "User:      $(o.username)")
    println(io, "Transfer:  $(o.active_mode ? "active" : "passive") mode")
    if (o.ssl)
        println(io, "Security:  $(o.implicit ? "implicit" : "explicit")")
    else
        println(io, "Security:  None")
    end
end


@doc """
Close FTP connection.
""" ->
function close(ftp::FTP)
    ftp_close_connection(ftp.ctxt)
end


@doc """
Download the file "file_name" from FTP server and return IOStream.
If "save_path" is not specified, contents are written to and returned as IOBuffer.
""" ->
function download(ftp::FTP, file_name::AbstractString, save_path::AbstractString="")
    resp = nothing
    try
        resp = ftp_get(ftp.ctxt, file_name, save_path)
    catch err
        if(isa(err, FTPClientError))
            err.msg = "Failed to download $file_name."
        end
        rethrow()
    end
    return resp.body
end


@doc """
Upload the file "local_name" to the FTP server and save as "local_name".
""" ->
function upload(ftp::FTP, local_name::AbstractString)
    return upload(ftp, local_name, local_name)
end


@doc """
Upload the file "local_name" to the FTP server and save as "remote_name".
""" ->
function upload(ftp::FTP, local_name::AbstractString, remote_name::AbstractString)
    open(local_name) do local_file
        return upload(ftp, local_file, remote_name)
    end
end

@doc """
Upload IO object "local_file" to the FTP server and save as "remote_name".
""" ->
function upload(ftp::FTP, local_file::IO, remote_name::AbstractString)
    resp = nothing
    try
        resp = ftp_put(ftp.ctxt, remote_name, local_file)
    catch err
        if(isa(err, FTPClientError))
            err.msg = "Failed to upload $remote_name."
        end
        rethrow()
    end
    return resp
end


@doc """
Returns the contents of the current working directory of the FTP server.
""" ->
function readdir(ftp::FTP)

    resp = nothing

    try
        resp = ftp_command(ftp.ctxt, "LIST")
    catch err
        if(isa(err, FTPClientError))
            err.msg = "Failed to list directories."
        end
        rethrow()
    end

    @compat dir = split(readstring(resp.body), '\n')
    dir = filter( x -> ~isempty(x), dir)
    dir = [ join(split(line)[9:end], ' ') for line in dir ]

end


@doc """
Sets the current working directory of the FTP server to "dir".
""" ->
function cd(ftp::FTP, dir::AbstractString)

    if (~endswith(dir, "/"))
        dir *= "/"
    end

    resp = ftp_command(ftp.ctxt, "CWD $dir")

    if(resp.code != 250)
        throw(FTPClientError("Failed to change to directory $dir. $resp.code", 0))
    end

end


@doc """
Get the current working directory of the FTP server
""" ->
function pwd(ftp::FTP)

    resp = ftp_command(ftp.ctxt, "PWD")

    if(resp.code != 257)
        throw(FTPClientError("Failed to get the current working directory. $resp.code", 0))
    end

    dir = split(resp.headers[end], '\"')[end-1]

end


@doc """
Delete file "file_name" from FTP server.
""" ->
function rm(ftp::FTP, file_name::AbstractString)

    resp = ftp_command(ftp.ctxt, "DELE $file_name")

    if(resp.code != 250)
        throw(FTPClientError("Failed to remove $file_name. $resp.code", 0))
    end

end


@doc """
Delete directory "dir_name" from FTP server.
""" ->
function rmdir(ftp::FTP, dir_name::AbstractString)

    resp = ftp_command(ftp.ctxt, "RMD $dir_name")

    if(resp.code != 250)
        throw(FTPClientError("Failed to remove $dir_name. $resp.code", 0))
    end

end


@doc """
Make directory "dir" on FTP server.
""" ->
function mkdir(ftp::FTP, dir::AbstractString)

    resp = ftp_command(ftp.ctxt, "MKD $dir")

    if(resp.code != 257)
        throw(FTPClientError("Failed to make $dir. $resp.code", 0))
    end

end


@doc """
Move (rename) file "file_name" to "new_name" on FTP server.
""" ->
function mv(ftp::FTP, file_name::AbstractString, new_name::AbstractString)

    resp = ftp_command(ftp.ctxt, "RNFR $file_name")

    if(resp.code != 350)
        throw(FTPClientError("Failed to move $file_name. $resp.code", 0))
    end

    resp = ftp_command(ftp.ctxt, "RNTO $new_name")

    if(resp.code != 250)
        throw(FTPClientError("Failed to move $file_name. $resp.code", 0))
    end

end


@doc """
Set the transfer mode to binary.
""" ->
function binary(ftp::FTP)

    ftp.ctxt.options.binary_mode = true
    resp = ftp_command(ftp.ctxt, "TYPE I")

    if(resp.code != 200)
        throw(FTPClientError("Failed to switch to binary mode. $resp.code", 0))
    end

end


@doc """
Set the transfer mode to ASCII.
""" ->
function ascii(ftp::FTP)

    ftp.ctxt.options.binary_mode = false
    resp = ftp_command(ftp.ctxt, "TYPE A")

    if(resp.code != 200)
        throw(FTPClientError("Failed to switch to ascii mode. $resp.code", 0))
    end

end
