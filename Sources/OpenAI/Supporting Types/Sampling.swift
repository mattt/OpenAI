/**
 The sampling method used by a model in completing a request.
 */
public enum Sampling: Hashable {
    /**
     Sampling temperature.

     Higher values means the model will take more risks.
     Try 0.9 for more creative applications,
     and 0 (argmax sampling) for ones with a well-defined answer.
     */
    case temperature(Double)

    /**
     Nucleus sampling.

     The model considers the results of the tokens with top_p probability mass.
     So 0.1 means only the tokens comprising the top 10% probability mass are considered.
     */
    case nucleus(Double)
}
