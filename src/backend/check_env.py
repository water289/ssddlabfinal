import os
from dotenv import load_dotenv

load_dotenv()
v = os.getenv('ADMIN_PASSWORD')
print('VALUE_REPR:', repr(v))
print('TYPE:', type(v))
print('LENGTH:', len(v) if v else 0)
