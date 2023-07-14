FROM truemark/aws-cli:alpine
COPY deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
