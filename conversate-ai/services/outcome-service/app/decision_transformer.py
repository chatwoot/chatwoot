import tensorflow as tf
from tensorflow.keras import layers

class MaskedTransformerBlock(layers.Layer):
    """
    A Transformer block with causal masking for autoregressive prediction.
    """
    def __init__(self, embed_dim, num_heads, ff_dim, rate=0.1):
        super(MaskedTransformerBlock, self).__init__()
        self.att = layers.MultiHeadAttention(num_heads=num_heads, key_dim=embed_dim)
        self.ffn = tf.keras.Sequential(
            [layers.Dense(ff_dim, activation="relu"), layers.Dense(embed_dim),]
        )
        self.layernorm1 = layers.LayerNormalization(epsilon=1e-6)
        self.layernorm2 = layers.LayerNormalization(epsilon=1e-6)
        self.dropout1 = layers.Dropout(rate)
        self.dropout2 = layers.Dropout(rate)

    def call(self, inputs, training, mask):
        attn_output = self.att(inputs, inputs, attention_mask=mask)
        attn_output = self.dropout1(attn_output, training=training)
        out1 = self.layernorm1(inputs + attn_output)
        ffn_output = self.ffn(out1)
        ffn_output = self.dropout2(ffn_output, training=training)
        return self.layernorm2(out1 + ffn_output)

class DecisionTransformer(tf.keras.Model):
    """
    A basic Decision Transformer model.
    """
    def __init__(
        self,
        state_dim,
        action_dim,
        embed_dim=128,
        max_ep_len=100,
        num_heads=4,
        ff_dim=128,
        num_layers=3,
        rate=0.1,
    ):
        super(DecisionTransformer, self).__init__()
        self.embed_dim = embed_dim
        self.state_dim = state_dim
        self.action_dim = action_dim
        self.max_ep_len = max_ep_len

        # Embeddings
        self.embed_timestep = layers.Embedding(max_ep_len, embed_dim)
        self.embed_return = layers.Dense(embed_dim)
        self.embed_state = layers.Dense(embed_dim)
        self.embed_action = layers.Embedding(action_dim, embed_dim)
        self.embed_ln = layers.LayerNormalization(epsilon=1e-6)

        # Transformer blocks
        self.transformer_blocks = [
            MaskedTransformerBlock(embed_dim, num_heads, ff_dim, rate)
            for _ in range(num_layers)
        ]

        # Prediction heads
        self.predict_return = layers.Dense(1)
        self.predict_state = layers.Dense(state_dim)
        self.predict_action = layers.Dense(action_dim, activation="softmax")

    def call(self, inputs, training=False):
        states, actions, returns_to_go, timesteps = inputs
        batch_size, seq_length = states.shape[0], states.shape[1]

        # Get causal mask
        causal_mask = self._get_causal_mask(seq_length)

        # Embeddings
        state_embed = self.embed_state(states)
        action_embed = self.embed_action(actions)
        return_embed = self.embed_return(returns_to_go)
        time_embed = self.embed_timestep(timesteps)

        # Reshape and add time embeddings
        state_embed += time_embed
        action_embed += time_embed
        return_embed += time_embed

        # Stack embeddings: (R_t, s_t, a_t) for each timestep
        stacked_inputs = tf.stack([return_embed, state_embed, action_embed], axis=2)
        stacked_inputs = tf.reshape(stacked_inputs, (batch_size, 3 * seq_length, self.embed_dim))
        stacked_inputs = self.embed_ln(stacked_inputs)

        # Transformer forward pass
        x = stacked_inputs
        for block in self.transformer_blocks:
            x = block(x, training, causal_mask)

        # Reshape back to (batch, seq_len, 3, embed_dim)
        x = tf.reshape(x, (batch_size, seq_length, 3, self.embed_dim))

        # Get predictions
        return_preds = self.predict_return(x[:, :, 0, :])
        state_preds = self.predict_state(x[:, :, 1, :])
        action_preds = self.predict_action(x[:, :, 2, :])

        return state_preds, action_preds, return_preds

    def _get_causal_mask(self, size):
        """
        Creates a causal mask for autoregressive prediction.
        """
        mask = 1 - tf.linalg.band_part(tf.ones((size * 3, size * 3)), -1, 0)
        return mask[tf.newaxis, tf.newaxis, :, :]

    def get_action(self, states, actions, returns, timesteps):
        """
        Get a single action prediction for the current step.
        """
        # This implementation expects sequences, so we pad the inputs
        # to the required sequence length.

        # Note: A more robust implementation would handle this padding
        # more carefully based on the model's training context length.

        states = tf.cast(tf.reshape(states, (1, -1, self.state_dim)), dtype=tf.float32)
        actions = tf.cast(tf.reshape(actions, (1, -1)), dtype=tf.int32)
        returns = tf.cast(tf.reshape(returns, (1, -1, 1)), dtype=tf.float32)
        timesteps = tf.cast(tf.reshape(timesteps, (1, -1)), dtype=tf.int32)

        _, action_preds, _ = self.call(
            (states, actions, returns, timesteps), training=False
        )
        return action_preds[0, -1] # Return the last action prediction
