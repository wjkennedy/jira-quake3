forge deploy -e production

#Then upgrade the production Jira install, for example:

forge install --upgrade --confirm-scopes --non-interactive -e production -p Jira -s one-atlas-ddag.atlassian.net
forge install --upgrade --confirm-scopes --non-interactive -e production -p Jira -s a9data.atlassian.net

#forge install --upgrade --confirm-scopes --non-interactive -e production -p Confluence -s one-atlas-ddag.atlassian.net

#For a9data.atlassian.net, production Confluence is also outdated:

forge install --upgrade --confirm-scopes --non-interactive -e production -p Confluence -s a9data.atlassian.net
forge install --upgrade --confirm-scopes --non-interactive -e production -p Jira -s a9data.atlassian.net
