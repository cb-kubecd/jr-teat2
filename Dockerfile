FROM scratch
EXPOSE 8080
ENTRYPOINT ["/jr-teat2"]
COPY ./bin/ /