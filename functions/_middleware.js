export async function onRequest(context) {
  const url = new URL(context.request.url);
  if (url.hostname === "jordan-howson.pages.dev") {
    url.hostname = "jordanhowson.com";
    return Response.redirect(url.toString(), 301);
  }
  return context.next();
}
