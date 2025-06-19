#!/usr/bin/env python3
import requests
import getpass
import pandas as pd
from copy import deepcopy
import urllib3

# Disable insecure HTTPS warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --------- CONFIGURABLE DEFAULTS ----------
GQL_URL = "https://example.com/gql"
USERNAME = 'example'
PASSWORD = 'example'  # Set to None to prompt at runtime
TEMPLATE_NAME = "TJ_Store Default"
ORG_NAME = "Example"
EXCEL_FILE_PATH = "site_codes.xlsx"
EXCEL_COLUMN_NAME = "SiteCode"
ICON_ID = "cabcsfyf30000266czq13py2e"  # <-- Use actual icon ID
# ------------------------------------------

def run_gql(url, payload, auth):
    response = requests.post(url, json=payload, verify=False, auth=auth)
    print(f"DEBUG Response Status: {response.status_code}")
    print(f"DEBUG Response Body: {response.text}")
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"GraphQL query failed with code {response.status_code}. Query: {payload['query']}")

def query_template_by_name(template_name, gql_url, auth):
    query = """
    query harTemplateNameToId($templateName: String!) {
        harTemplates(search: {name: {eq: $templateName}}) {
            edges {
                node {
                    id
                    definition
                }
            }
        }
    }
    """
    payload = {'query': query, 'variables': {"templateName": template_name}}
    return run_gql(gql_url, payload, auth)['data']['harTemplates']['edges'][0]['node']

def query_organization_id_by_name(org_name, gql_url, auth):
    query = """
    query orgNameToOrgId($companyName:String!) {
        organizations(search: { company: { eq: $companyName } }) {
            edges {
                node {
                    id
                }
            }
        }
    }
    """
    payload = {'query': query, 'variables': {"companyName": org_name}}
    return run_gql(gql_url, payload, auth)['data']['organizations']['edges'][0]['node']['id']

def create_from_har_template(template_id, definition, gql_url, auth):
    query = """
    mutation createFromHarTemplate($templateId:ID!, $definition:JSON!) {
        createFromHarTemplate(id: $templateId, definition:$definition) {
            harProviders {
                id
                name
                type
                organization {
                    company
                }
            }
        }
    }
    """
    payload = {'query': query, 'variables': {"templateId": template_id, "definition": definition}}
    return run_gql(gql_url, payload, auth)

def set_icon_for_har_provider(har_provider_id, icon_id, gql_url, auth):
    mutation = """
    mutation setHarProviderIcon($harProviderId: ID!, $icon: ID) {
      setHarProviderIcon(harProviderId: $harProviderId, iconId: $icon) {
        id
        name
      }
    }
    """
    variables = {
        "harProviderId": har_provider_id,
        "icon": icon_id
    }
    payload = {'query': mutation, 'variables': variables}
    return run_gql(gql_url, payload, auth)

def modify_and_create_for_site(site_code, template_definition, org_id, template_id, gql_url, auth):
    modified_definition = deepcopy(template_definition)
    for har_provider in modified_definition['harProviders']:
        har_provider['organization']['id'] = org_id
        har_provider['contactOrganization']['id'] = org_id
        har_provider['name'] += f"-0{site_code}"

        old_filter = har_provider['filter']['filter']
        old_search = har_provider['filter']['search']
        har_provider['filter']['filter'] = f"({old_filter}) and (name contains {site_code})"
        har_provider['filter']['search'] = {
            "and": [
                old_search,
                {
                    "name": {
                        "contains": site_code
                    }
                }
            ]
        }

    result = create_from_har_template(template_id, modified_definition, gql_url, auth)

    for hp in result['data']['createFromHarTemplate']['harProviders']:
        set_icon_for_har_provider(hp['id'], ICON_ID, gql_url, auth)

    return result

######## MAIN SCRIPT ########

if PASSWORD is None:
    PASSWORD = getpass.getpass(prompt='Password: ')
auth = (USERNAME, PASSWORD)

print(f"\nUsing endpoint: {GQL_URL}")
print(f"Using template: {TEMPLATE_NAME}")
print(f"Using organization: {ORG_NAME}")
print(f"Using Excel file: {EXCEL_FILE_PATH} (Column: {EXCEL_COLUMN_NAME})")

template_info = query_template_by_name(TEMPLATE_NAME, GQL_URL, auth)
template_def = template_info['definition']
template_id = template_info['id']
org_id = query_organization_id_by_name(ORG_NAME, GQL_URL, auth)

df = pd.read_excel(EXCEL_FILE_PATH)
df[EXCEL_COLUMN_NAME] = df[EXCEL_COLUMN_NAME].astype(str)
site_codes = df[EXCEL_COLUMN_NAME].dropna().unique()

print("\nCreating services for site codes:")
for site_code in site_codes:
    site_code = str(site_code)
    print(f" -> Creating for site code: {site_code}")
    result = modify_and_create_for_site(site_code, template_def, org_id, template_id, GQL_URL, auth)
    for hp in result['data']['createFromHarTemplate']['harProviders']:
        print(f"   Created: {hp['name']} (ID: {hp['id']}) with updated icon")

