var port =
  process.env.PORT ||
  (console.log("PORT environment variable not set"), process.exit(1));
const votesApiHost =
  process.env.VOTES_API_HOST ||
  (console.log("VOTES_API_HOST environment variable not set"), process.exit(1));
const votesApiPort =
  process.env.VOTES_API_PORT ||
  (console.log("VOTES_API_PORT environment variable not set"), process.exit(1));

var express = require("express"),
  async = require("async"),
  http = require("http"),
  path = require("path"),
  cookieParser = require("cookie-parser"),
  bodyParser = require("body-parser"),
  methodOverride = require("method-override"),
  app = express(),
  server = require("http").Server(app),
  io = require("socket.io")(server);

io.set("transports", ["polling"]);

io.sockets.on("connection", function (socket) {
  socket.emit("message", { text: "Welcome!" });

  socket.on("subscribe", function (data) {
    socket.join(data.channel);
  });
});

function startPolling() {
  console.log("Starting to poll votes API...");
  console.log(`Votes API URL: http://${votesApiHost}:${votesApiPort}/results`);

  getVotes();
}

startPolling();

function getVotes() {
  console.log("Fetching votes from API...");

  const options = {
    hostname: votesApiHost,
    port: votesApiPort,
    path: "/results",
    method: "GET",
  };

  const req = http.request(options, (res) => {
    let data = "";

    res.on("data", (chunk) => {
      data += chunk;
    });

    res.on("end", () => {
      try {
        if (res.statusCode === 200) {
          const votes = JSON.parse(data);
          console.log("API call successful, got votes:", votes);
          io.sockets.emit("scores", JSON.stringify(votes));
          // Clear any previous errors
          io.sockets.emit("error", null);
        } else {
          console.error("API Error: Status", res.statusCode);
          io.sockets.emit("error", {
            message: "API Error: Status " + res.statusCode,
            detail: data || "Failed to fetch results from votes API",
          });
        }
      } catch (parseError) {
        console.error("JSON Parse Error:", parseError.message);
        io.sockets.emit("error", {
          message: "Parse Error: " + parseError.message,
          detail: "Failed to parse response from votes API",
        });
      }

      setTimeout(function () {
        getVotes();
      }, 1000);
    });
  });

  req.on("error", (err) => {
    console.error("Request Error:", err.message);
    io.sockets.emit("error", {
      message: "Connection Error: " + err.message,
      detail:
        "Failed to connect to votes API at " +
        votesApiHost +
        ":" +
        votesApiPort,
    });

    setTimeout(function () {
      getVotes();
    }, 5000); // Retry after 5 seconds on connection error
  });

  req.end();
}

app.use(cookieParser());
app.use(bodyParser());
app.use(methodOverride("X-HTTP-Method-Override"));
app.use(function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );
  res.header("Access-Control-Allow-Methods", "PUT, GET, POST, DELETE, OPTIONS");
  next();
});

app.use(express.static(__dirname + "/views"));

app.get("/", function (req, res) {
  res.sendFile(path.resolve(__dirname + "/views/index.html"));
});

app.get("/healthz", function (req, res) {
  res.json({ status: "ok" });
});

server.listen(port, function () {
  var port = server.address().port;
  console.log("App running on port " + port);
});
