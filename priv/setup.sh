apt update
apt install -y python-pip
pip install -y --upgrade pip
pip install spacy-nightly
python -m spacy download en_core_web_sm-2.0.0-alpha --direct
