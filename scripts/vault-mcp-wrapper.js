#!/usr/bin/env node

/**
 * Wrapper MCP simple pour Vault qui fonctionne localement
 * Alternative au serveur Docker qui ne fonctionne pas sur Mac ARM
 */

const { spawn } = require('child_process');
const readline = require('readline');

const VAULT_ADDR = process.env.VAULT_ADDR || 'http://localhost:8200';
const VAULT_TOKEN = process.env.VAULT_TOKEN || '';

// Fonction pour exécuter une commande vault
function execVault(args) {
  return new Promise((resolve, reject) => {
    const vault = spawn('vault', args, {
      env: {
        ...process.env,
        VAULT_ADDR,
        VAULT_TOKEN
      }
    });

    let stdout = '';
    let stderr = '';

    vault.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    vault.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    vault.on('close', (code) => {
      if (code === 0) {
        resolve(stdout);
      } else {
        reject(new Error(stderr || stdout));
      }
    });
  });
}

// Handler pour read_secret
async function readSecret(path) {
  try {
    // Essayer d'abord avec le chemin direct
    const result = await execVault(['kv', 'get', '-format=json', path]);
    const data = JSON.parse(result);
    return {
      content: [{
        type: 'text',
        text: JSON.stringify(data.data.data, null, 2)
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error reading secret: ${error.message}`
      }],
      isError: true
    };
  }
}

// Handler pour list_secrets
async function listSecrets(path) {
  try {
    const result = await execVault(['kv', 'list', '-format=json', path]);
    const keys = JSON.parse(result);
    return {
      content: [{
        type: 'text',
        text: JSON.stringify(keys, null, 2)
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error listing secrets: ${error.message}`
      }],
      isError: true
    };
  }
}

// Handler pour list_all_mcp_secrets
async function listAllMcpSecrets() {
  try {
    const result = await execVault(['kv', 'list', '-format=json', 'datligent/mcp/shared']);
    const secrets = JSON.parse(result) || [];

    const secretsInfo = secrets.map(name => {
      return `- datligent/mcp/shared/${name}`;
    }).join('\n');

    return {
      content: [{
        type: 'text',
        text: `Available MCP secrets in Vault:\n\n${secretsInfo}\n\nTo read a secret, use read_secret with path like "datligent/mcp/shared/github"`
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error listing MCP secrets: ${error.message}`
      }],
      isError: true
    };
  }
}

// Interface MCP stdio
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on('line', async (line) => {
  try {
    const request = JSON.parse(line);

    if (request.method === 'initialize') {
      const response = {
        jsonrpc: '2.0',
        id: request.id,
        result: {
          protocolVersion: '2024-11-05',
          capabilities: {
            tools: {},
            resources: {}
          },
          serverInfo: {
            name: 'vault-mcp-wrapper',
            version: '1.0.0'
          }
        }
      };
      console.log(JSON.stringify(response));
    } else if (request.method === 'resources/list') {
      const response = {
        jsonrpc: '2.0',
        id: request.id,
        result: {
          resources: []
        }
      };
      console.log(JSON.stringify(response));
    } else if (request.method === 'tools/list') {
      const response = {
        jsonrpc: '2.0',
        id: request.id,
        result: {
          tools: [
            {
              name: 'read_secret',
              description: 'Read a secret from Vault',
              inputSchema: {
                type: 'object',
                properties: {
                  path: { type: 'string', description: 'Path to the secret (e.g., secret/mcp/github or datligent/mcp/shared/github)' }
                },
                required: ['path']
              }
            },
            {
              name: 'list_secrets',
              description: 'List secrets at a path',
              inputSchema: {
                type: 'object',
                properties: {
                  path: { type: 'string', description: 'Path to list (e.g., secret/mcp or datligent/mcp/shared)' }
                },
                required: ['path']
              }
            },
            {
              name: 'list_all_mcp_secrets',
              description: 'List all available MCP secrets in Vault (datligent/mcp/shared)',
              inputSchema: {
                type: 'object',
                properties: {},
                additionalProperties: false
              }
            }
          ]
        }
      };
      console.log(JSON.stringify(response));
    } else if (request.method === 'tools/call') {
      const { name, arguments: args } = request.params;
      let result;

      if (name === 'read_secret') {
        result = await readSecret(args.path);
      } else if (name === 'list_secrets') {
        result = await listSecrets(args.path);
      } else if (name === 'list_all_mcp_secrets') {
        result = await listAllMcpSecrets();
      } else {
        result = {
          content: [{ type: 'text', text: `Unknown tool: ${name}` }],
          isError: true
        };
      }

      const response = {
        jsonrpc: '2.0',
        id: request.id,
        result
      };
      console.log(JSON.stringify(response));
    }
  } catch (error) {
    const response = {
      jsonrpc: '2.0',
      id: request.id || null,
      error: {
        code: -32603,
        message: error.message
      }
    };
    console.log(JSON.stringify(response));
  }
});

// MCP stdio server ready (no console output to avoid breaking protocol)
