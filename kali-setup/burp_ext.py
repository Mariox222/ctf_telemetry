from burp import IBurpExtender, IHttpListener, IExtensionHelpers
from java.io import PrintWriter, OutputStreamWriter, BufferedWriter
from java.net import URL, HttpURLConnection
from java.nio.charset import StandardCharsets
import json
import datetime
import base64

class BurpExtender(IBurpExtender, IHttpListener):
    def registerExtenderCallbacks(self, callbacks):
        self._callbacks = callbacks
        self._helpers = callbacks.getHelpers()
        self._callbacks.setExtensionName("Elasticsearch Logger")
        self._stdout = PrintWriter(callbacks.getStdout(), True)
        self._stderr = PrintWriter(callbacks.getStderr(), True)
        # Register HTTP listener
        callbacks.registerHttpListener(self)
        # Elasticsearch setup
        self.es_url = 'http://51.107.3.131:9200/burp-traffic/_doc/'
        self.es_auth = base64.b64encode('filebeat_user:ZtTiwDQFXaoRx1qMe5/kbaJkjPIboMVS').decode('utf-8')
        self._stdout.println("Elasticsearch Logger extension loaded")

    def processHttpMessage(self, toolFlag, messageIsRequest, messageInfo):
        # Only process requests, skip responses
        if not messageIsRequest:
            return

        try:
            timestamp = datetime.datetime.utcnow().isoformat() + 'Z'
            self._stdout.println("Processing request")
            request = messageInfo.getRequest()
            request_info = self._helpers.analyzeRequest(request)
            headers = request_info.getHeaders()
            body = request[request_info.getBodyOffset():].tostring()
            request_line = headers[0]
            method, path, _ = request_line.split(' ', 2)
            # Construct the full URL
            http_service = messageInfo.getHttpService()
            scheme = 'https' if http_service.getPort() == 443 else 'http'
            url = "{}://{}:{}{}".format(scheme, http_service.getHost(), http_service.getPort(), path)
            data = {
                'tool': self._callbacks.getToolName(toolFlag),
                'type': 'request',
                'timestamp': timestamp,
                'url': url,
                'headers': list(headers),
                'body': body
            }
            self._stdout.println("Request data prepared: " + json.dumps(data))
            self._stdout.println("Sending data to Elasticsearch")
            self.send_to_elasticsearch(data)
        except Exception as e:
            self._stderr.println("Error processing HTTP message: " + str(e))

    def send_to_elasticsearch(self, data):
        try:
            payload = json.dumps(data)
            url = URL(self.es_url)
            conn = url.openConnection()
            conn.setDoOutput(True)
            conn.setRequestMethod('POST')
            conn.setRequestProperty('Content-Type', 'application/json')
            conn.setRequestProperty('Authorization', 'Basic ' + self.es_auth)
            writer = BufferedWriter(OutputStreamWriter(conn.getOutputStream(), 'UTF-8'))
            writer.write(payload)
            writer.flush()
            writer.close()
            status = conn.getResponseCode()
            self._stdout.println("Elasticsearch response status: {}".format(status))
            if status not in [200, 201]:
                self._stderr.println("Failed to send data to Elasticsearch, status: " + str(status))
        except Exception as e:
            self._stderr.println("Error sending data to Elasticsearch: " + str(e))
