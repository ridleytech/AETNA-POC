var express = require("express");
var router = express.Router();
var dotenv = require("dotenv");
const axios = require("axios");

dotenv.config();

const watsonAuth = process.env.WATSON_AUTH;
const watsonSkillID = process.env.WATSON_SKILL_ID;
const discoveryAuth = process.env.DISCOVERY_AUTH;
const discoveryInstanceID = process.env.DISCOVERY_INSTANCE_ID;
const discoveryProjectID = process.env.DISCOVERY_PROJECT_ID;

//Endpoint to process Watson assistant webhook calls

router.post("/processResponse", function (req, res, next) {
  //routes calls from iOS app and IBM Watson Assistant webhook
  processResponse(req, res);
});

const processResponse = (req, res) => {
  // console.log("processResponse req.body", req.body);

  if (req.body.data == "message") {
    // handles iOS message api call

    sendWatsonMessage(req, res);
  } else if (req.body.discoveryMessage) {
    // handles Watson discovery api call

    sendDiscoveryMessage(req, res);
  } else if (req.body.providers) {
    // handles Watson webhook api call for providers info

    getProviders(req, res);
  } else {
    console.log("no params");
    res.send({
      status: "success",
      data: "Webhook successful. No valid params were provided from Watson to process response.",
    });
  }

  if (req.body.insertLog) {
    console.log("insertLog");
    insertLog(req, res);
  }
};

const sendWatsonMessage = async (req, res) => {
  var data = {
    input: {
      text: req.body.userMessage,
    },
  };

  if (req.body.context) {
    data.context = req.body.context;
  }

  var url = `https://api.us-south.assistant.watson.cloud.ibm.com/v1/workspaces/${watsonSkillID}/message?version=2019-02-28`;

  let config = {
    method: "post",
    maxBodyLength: Infinity,
    url: url,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${watsonAuth}`,
    },
    data: JSON.stringify(data),
  };

  axios
    .request(config)
    .then((response) => {
      res.send({ status: "successful", data: response.data });
    })
    .catch((error) => {
      console.log(error);

      res.send({ status: "error", data: error });
    });
};

const sendDiscoveryMessage = async (req, res) => {
  let utterance = req.body.discoveryMessage;
  let entities = req.body.entities;

  let data = JSON.stringify({
    natural_language_query: utterance,
    filter: 'document_type::"policy_certificate"',
    count: 3,
    return: [
      "title",
      "issuer",
      "policy_number",
      "group_number",
      "effective_date",
      "expiration_date",
      "sections",
      "structured",
      "text",
    ],
    spelling_suggestions: true,
    highlight: true,
    passages: {
      enabled: true,
      fields: [
        "text",
        "sections.body",
        "sections.heading",
        "structured.plan.*",
        "structured.cost_sharing_in_network.*",
        "structured.cost_sharing_out_of_network.*",
        "structured.pharmacy.*",
        "structured.authorization_rules.*",
        "structured.service_limits.*",
        "structured.examples.*",
        "structured.contact.*",
      ],
      find_answers: true,
      characters: 300,
    },
    table_results: {
      enabled: false,
    },
  });

  let config = {
    method: "post",
    maxBodyLength: Infinity,
    url: `https://api.us-south.discovery.watson.cloud.ibm.com/instances/${discoveryInstanceID}/v2/projects/${discoveryProjectID}/query?version=2022-08-01`,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${discoveryAuth}`,
    },
    data: data,
  };

  axios
    .request(config)
    .then((response) => {
      var botResponse;

      console.log("Discovery response:", response.data);

      if (entities[0] && entities[0].entity == "insurance_item") {
        if (entities[0].value == "in_network_deductible") {
          const { answer, provenance } = getInNetworkDeductible(response.data);

          console.log("In-network individual deductible:", answer);
          console.log("Provenance:", provenance);

          botResponse = `Your in-network deductible is ${answer}.`;
        }
      }

      res.send({ status: "successful", botResponse });
    })
    .catch((error) => {
      console.log("sendDiscoveryMessage error", error);
      res.send({ status: "error", data: error });
    });
};

const getProviders = (req, res) => {
  //mocks database call to retrieve providers

  const data = {
    providers: [
      {
        name: "Dr. Lisa Hernandez, MD",
        address: "1200 McKinney St, Houston, TX 77010",
        distance_miles: 1.2,
      },
      {
        name: "Dr. Kevin Patel, DO",
        address: "500 Crawford St, Suite 250, Houston, TX 77002",
        distance_miles: 0.6,
      },
      {
        name: "Dr. Maria Gomez, MD",
        address: "1415 Louisiana St, Houston, TX 77002",
        distance_miles: 0.8,
      },
      {
        name: "Dr. Angela Wu, MD",
        address: "2800 Kirby Dr, Suite B100, Houston, TX 77098",
        distance_miles: 3.4,
      },
      {
        name: "Dr. Brian Thompson, MD",
        address: "3201 Allen Pkwy, Houston, TX 77019",
        distance_miles: 2.9,
      },
    ],
  };

  res.send({
    status: "successful",
    data,
    queryType: "providers",
    recordTotal: data.providers.length,
  });
};

// Pass in the raw Discovery JSON response you posted
function getInNetworkDeductible(resp) {
  const formatUSD = (n) => `$${Number(n).toLocaleString("en-US")}`;

  // 1) Prefer structured field
  for (const r of resp.results || []) {
    const val = r?.structured?.cost_sharing_in_network?.deductible_individual;
    if (val != null) {
      return {
        answer: formatUSD(val),
        provenance: {
          document_id: r.document_id,
          field: "structured.cost_sharing_in_network.deductible_individual",
        },
      };
    }
  }

  // 2) Look in sections/text for "Individual Deductible: $X" under In-Network
  const rx = /Individual\s+Deductible:\s*\$?\s*([\d,]+)/i;
  for (const r of resp.results || []) {
    // Scan sections
    for (const s of r.sections || []) {
      const isInNetworkSection =
        /in[-\s]?network/i.test(s.heading || "") ||
        /In-Network:/i.test(s.body || "");
      if (isInNetworkSection) {
        const m = (s.body || "").match(rx);
        if (m) {
          return {
            answer: formatUSD(m[1].replace(/,/g, "")),
            provenance: { document_id: r.document_id, field: "sections.body" },
          };
        }
      }
    }
    // Scan flattened text array
    for (const t of r.text || []) {
      const isInNetworkContext = /In[-\s]?Network/i.test(t);
      if (isInNetworkContext) {
        const m = t.match(rx);
        if (m) {
          return {
            answer: formatUSD(m[1].replace(/,/g, "")),
            provenance: { document_id: r.document_id, field: "text" },
          };
        }
      }
    }
  }

  // 3) Last resort: use passage answers if clearly in an in-network/deductible context
  for (const r of resp.results || []) {
    for (const p of r.document_passages || []) {
      const hasContext =
        /in[-\s]?network/i.test(p.passage_text || "") &&
        /deductible/i.test(p.passage_text || "");
      if (hasContext) {
        // Try the same regex in the passage text first
        const m = (p.passage_text || "").match(rx);
        if (m) {
          return {
            answer: formatUSD(m[1].replace(/,/g, "")),
            provenance: {
              document_id: r.document_id,
              field: "document_passages.passage_text",
            },
          };
        }
        // Or take the first “answer” span if present
        const a = (p.answers || [])[0]?.answer_text;
        if (a) {
          const num = Number(String(a).replace(/[^\d]/g, ""));
          if (!Number.isNaN(num)) {
            return {
              answer: formatUSD(num),
              provenance: {
                document_id: r.document_id,
                field: "document_passages.answers[0]",
              },
            };
          }
        }
      }
    }
  }

  return { answer: null, provenance: null };
}

module.exports = router;
