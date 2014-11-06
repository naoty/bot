import socket
import os.path
import random
from gensim.models import word2vec

class SynonymServer:
    MODEL_PATH = "../../../assets/wikipedia.model"

    def __init__(self):
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

    def start(self, socket_path):
        self._init_word2vec_model()
        self.socket.bind(socket_path)
        self.socket.listen(5)

        try:
            while True:
                connection, address = self.socket.accept()
                data = connection.recv(1024)
                while len(data) > 0:
                    synonym = self._get_synonym(data.decode("utf-8"))
                    connection.send(synonym.encode("utf-8"))
                    data = connection.recv(1024)
                else:
                    connection.close()
        finally:
            os.remove(socket_path)

    def _init_word2vec_model(self):
        base_path = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.normpath(os.path.join(base_path, SynonymServer.MODEL_PATH))
        self.model = word2vec.Word2Vec.load(model_path)

    def _get_synonym(self, word):
        try:
            similar_words = self.model.most_similar(positive=[word])
            synonyms = [word for word, score in similar_words]
            return random.choice(synonyms)
        except KeyError:
            return word
