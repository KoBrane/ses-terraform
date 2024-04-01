"""
Lambda function to process inbound emails by copying them to a different folder with a new human parseable object key
and adding tags to the new object from the email header values.

Note that the filename and tag values are sanitized to remove any characters that are not allowed in S3 object keys or tags:
- Filename components are sanitized to remove most non-alphanumeric characters 
- Tag values are sanitized to remove any character that is not in the set of allowed characters, and then truncated to a
maximum of 256 characters. 
- See functions sanitize_filename_component and sanitize_object_tag_value for details.
"""

import boto3
import os
import email
import logging
from email.utils import parseaddr, parsedate_to_datetime
from datetime import datetime
import re

import urllib.parse

s3 = boto3.client("s3")

logging.getLogger('__main__').setLevel(logging.DEBUG)
logging.getLogger('botocore').setLevel(logging.WARN)


def sanitize_filename_component(component):
    """
    Sanitize a string to be used as a part of a multi-component filename in which the components will be separated 
    by an underscore.
    The string will be trimmed of leading and trailing whitespace, and any non-alphanumeric or hyphen or period 
    characters will be replaced with hyphens. Multiple hyphens will be replaced with a single hyphen.

    Parameters:
        component (str): The string to be sanitized.

    Returns:
        str: The sanitized string.
    """
    #first trim the input
    sanitized_component = component.strip()
    # do a special case replacement of the @ symbol
    sanitized_component = sanitized_component.replace('@', 'AT')
    # then replace all other non-alphanumeric or hyphen or period characters with hyphens
    sanitized_component = re.sub(r'[^a-zA-Z0-9-.]', '-', sanitized_component)

    #finally replace multiple hyphens with a single hyphen
    sanitized_component = re.sub(r'-+', '-', sanitized_component)
    
    return sanitized_component


def sanitize_object_tag_value(tag_value):
    """
    Sanitize a string to be used as a value of an object tag. The string will be trimmed of leading and trailing
    whitespace, then any character that is not in the set of allowed characters will be removed. The allowed set
    of characters is: letters (a-z, A-Z), numbers (0-9), and spaces representable in UTF-8, and the following 
    characters: + - = . _ : / @
    Finally the string will be truncated to max 256 characters.

    Parameters:
        tag_value (str): The string to be sanitized.

    Returns:
        str: The sanitized string.
    """
    # Trim leading and trailing whitespace
    sanitized_tag_value = tag_value.strip()
    # Remove any character that is not in the set of allowed characters
    sanitized_tag_value = re.sub(r'[^a-zA-Z0-9-+=._:/@ ]', '', sanitized_tag_value)
    # Truncate to max 256 characters
    sanitized_tag_value = sanitized_tag_value[:256]
    return sanitized_tag_value


def lambda_handler(event, context):
    """
    Lambda handler function to process inbound emails.
    This function will be triggered by an S3 event when a new email is uploaded to the S3 bucket.

    Parameters:
        event (dict): The event data. This is a dictionary with an S3 event record in the 'Records' key.
        context (object): The lambda context object (not used).
    """
    destination_folder = os.environ['PROCESSED_EMAILS_FOLDER']
    main_folder = os.environ['MAIN_EMAILS_FOLDER']

    # bail out if the destination folder is the same as the main folder to avoid a loop
    if destination_folder == main_folder:
        logging.error(f"Destination folder '{destination_folder}' is the same as the main folder.")
        return {"status": "error"}   

    # bail out if no valid event records found
    if not event or 'Records' not in event:
        logging.debug("No valid event records found.")
        return None

    # loop through the lambda event records
    for record in event['Records']:
        s3_event = record['s3']
        bucket_name = s3_event['bucket']['name']

        object_key = urllib.parse.unquote_plus(s3_event['object']['key'], encoding='utf-8')  

        response = s3.get_object(Bucket=bucket_name, Key=object_key)
        file_content = response['Body'].read()

        # Create an email message object using the content of the file
        msg = email.message_from_bytes(file_content)

        # Extract relevant information from the email message
        sender  = parseaddr(msg['From'])[1]  # the parse function collects email address from the "From" header into a tuple (realname, email_address) and [1] passes the email address
        to_addresses = msg.get_all('To', [])
        # check that there is at least one recipient
        if not to_addresses:
            to = 'None'
            tos = ''
        else:
            tos_list = [parseaddr(addr)[1] for addr in to_addresses]
            to = tos_list[0]
            tos = ','.join(tos_list)
        #repeat for CCs
        cc_addresses = msg.get_all('Cc', [])
        if not cc_addresses:
            ccs = ''
        else:
            cc_list = [parseaddr(addr)[1] for addr in cc_addresses]
            ccs = ','.join(cc_list)

        sent_date = parsedate_to_datetime(msg['Date'])
        formatted_date = sent_date.strftime('%Y-%m-%d') 
        formatted_time = sent_date.strftime('%H:%M:%S')
        formatted_datetime = f"{formatted_date} {formatted_time}"

        subject = msg['Subject']
        
        # Concatenate the components into a file name
        sanitized_subject = sanitize_filename_component(subject)
        sanitized_to = sanitize_filename_component(to)
        sanitized_sender = sanitize_filename_component(sender)
        filename = f"{sanitized_subject}_{sanitized_to}_{sanitized_sender}.eml"
        # create the full new s3 object key
        new_object_key= os.path.join(destination_folder, formatted_date, filename)

        # Copy the object
        s3.copy_object(Bucket = bucket_name, 
                        CopySource = {'Bucket': bucket_name, 'Key': object_key}, 
                        Key = new_object_key)
        logging.debug(f"Converted inbound email to .eml and copied to: {new_object_key}")

        # Define tags, sanitizing the values
        tags = {
            'sender': sanitize_object_tag_value(sender),
            'to': sanitize_object_tag_value(tos),
            'cc': sanitize_object_tag_value(ccs),
            'sent_date': formatted_date,
            'sent_time': formatted_time,
            'sent_datetime': formatted_datetime,
            'subject': sanitize_object_tag_value(subject)
        }

         # Convert tags to the format required by S3
        tag_set = [{'Key': k, 'Value': v} for k, v in tags.items()]

        # Update the S3 object tags for the destination object
        s3.put_object_tagging(
            Bucket = bucket_name,
            Key = new_object_key,
            Tagging = { 'TagSet': tag_set }
        )
    #end for
# end lambda_handler