FROM public.ecr.aws/nginx/nginx:alpine
ARG BUILD_NUMBER=local
COPY app/index.html /usr/share/nginx/html/index.html
RUN sed -i "s/__BUILD__/${BUILD_NUMBER}/" /usr/share/nginx/html/index.html
EXPOSE 80
