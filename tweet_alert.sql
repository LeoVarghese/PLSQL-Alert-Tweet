PROCEDURE tweet_alert (
   p_user       IN   VARCHAR2,
   p_password   IN   VARCHAR2,
   p_message    IN   VARCHAR2,
   p_debug      IN   BOOLEAN := TRUE
)
IS
   l_host       CONSTANT VARCHAR2 (20)   := 'api.twitter.com';
   l_protocol   CONSTANT VARCHAR2 (20)   := 'http://';
   l_request             UTL_HTTP.req;
   l_response            UTL_HTTP.resp;
   l_tweet_url           VARCHAR2 (255);
   l_content             VARCHAR2 (255);
   l_message             VARCHAR2 (140);
   l_line                VARCHAR2 (1024);
BEGIN
   l_message := SUBSTR (p_message, 1, 140);
   -- 140 characters per tweet
   l_content := 'status=' || utl_url.ESCAPE (l_message);
   l_tweet_url := l_protocol || l_host || '/1/statuses/update.xml';
   -- building the request
   l_request := UTL_HTTP.begin_request (url         => l_tweet_url,
                                        method      => 'POST');
   -- set the request headers
   UTL_HTTP.set_header (r          => l_request,
                        NAME       => 'User-Agent',
                        VALUE      => 'Mozilla/4.0'
                       );
   UTL_HTTP.set_header (r          => l_request,
                        NAME       => 'Content-Type',
                        VALUE      => 'application/x-www-form-urlencoded'
                       );
   UTL_HTTP.set_header (r          => l_request,
                        NAME       => 'Content-Length',
                        VALUE      => LENGTH (l_content)
                       );
   -- user authentication
   UTL_HTTP.set_authentication (r             => l_request,
                                username      => p_user,
                                PASSWORD      => p_password
                               );
   -- writing the content
   UTL_HTTP.write_text (r => l_request, DATA => l_content);

   -- getting the response
   BEGIN
      l_response := UTL_HTTP.get_response (r => l_request);

      IF p_debug
      THEN
         BEGIN
            LOOP
               UTL_HTTP.read_line (r                => l_response,
                                   DATA             => l_line,
                                   remove_crlf      => TRUE
                                  );
               DBMS_OUTPUT.put_line (l_line);
            END LOOP;
         EXCEPTION
            WHEN UTL_HTTP.end_of_body
            THEN
               -- no more data
               NULL;
         END;
      END IF;

      -- end the reponse
      UTL_HTTP.end_response (r => l_response);
   END;-- of the response
EXCEPTION
   WHEN OTHERS
   THEN
      UTL_HTTP.end_response (r => l_response);
      DBMS_OUTPUT.put_line ('request failed: '
                            || UTL_HTTP.get_detailed_sqlerrm
                           );
      RAISE;
END tweet;
