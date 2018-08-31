import json
import re
import socketserver
import threading


HOST, PORT = "0.0.0.0", 25826

syslog_pattern = re.compile(r"\S* (\S*) \S* (\S*) \d+ \S* (?:- )?(.*)")


class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    pass


class ThreadedTCPRequestHandler(socketserver.StreamRequestHandler):
    """
    The RequestHandler class for our server.

    It is instantiated once per connection to the server, and must
    override the handle() method to implement communication to the
    client.
    """

    def handle(self):
        while(True):
            data = bytes.decode(self.rfile.readline().strip())
            if data == "":
                print("Connection closed", flush=True)
                break
            # Match the syslog string format to get the actual original message out
            # The - is optional as it seemed to appear from nowhere recently.
            m = re.match(syslog_pattern, data)
            if m is None:
                # Not syslog format for some reason, just send raw message to console and file
                print(data, flush=True)
                #with open("/log-dir/log.txt", 'a') as file_:
                    #file_.write(data + '\n')
            else:
                # Now, is the message valid JSON?
                try:
                    json_object = json.loads(m.group(3))
                    # Yes. Get the values out of it (with sensible defaults)
                    level = json_object.get("level", "")
                    traceid = json_object.get("traceid", "")
                    exception = json_object.get("exception", "")
                    message = json_object.get("message", "")
                    # Send nicely structured message to console and file
                    data = "{0} {1} {2} {3} {4} {5}".format(m.group(1), m.group(2), level, message, exception, traceid)
                    print(data, flush=True)
                    #with open("/log-dir/log.txt", 'a') as file_:
                        #file_.write(data + '\n')
                except ValueError:
                    # Nope. Send half-structured message to console and file
                    data = "{0} {1} {2}".format(m.group(1), m.group(2), m.group(3))
                    print(data, flush=True)
                    #with open("/log-dir/log.txt", 'a') as file_:
                        #file_.write(data + '\n')


if __name__ == "__main__":
    try:
        server = ThreadedTCPServer((HOST, PORT), ThreadedTCPRequestHandler)
        # Start a thread with the server -- that thread will then start one
        # more thread for each request
        server_thread = threading.Thread(target=server.serve_forever)
        server_thread.start()
        print("Server loop running in thread:", server_thread.name, flush=True)
    except (IOError, SystemExit):
        server.shutdown()
        server.server_close()
        raise
    except KeyboardInterrupt:
        print("Crtl+C Pressed. Shutting down.", flush=True)
