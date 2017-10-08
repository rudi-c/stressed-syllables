apt update
apt install -y python-pip
python -m pip install -U virtualenv
virtualenv .env
source .env/bin/activate
pip install spacy-nightly
python -m spacy download en_core_web_sm
