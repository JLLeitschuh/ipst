/**
 * Copyright (c) 2016, All partners of the iTesla project (http://www.itesla-project.eu/consortium)
 * Copyright (c) 2017, RTE (http://www.rte-france.com)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
package eu.itesla_project.mcla.forecast_errors;

import com.powsybl.commons.config.ModuleConfig;
import com.powsybl.commons.config.PlatformConfig;
import eu.itesla_project.mcla.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.file.Path;
import java.util.Objects;
/*
   MCLA code 1.8.1
*/

/**
 * @author Quinary <itesla@quinary.com>
 */
public class ForecastErrorsAnalyzerConfig {

    private static final Logger LOGGER = LoggerFactory.getLogger(ForecastErrorsAnalyzerConfig.class);

    private Path binariesDir;
    private Path runtimeHomeDir;
    private final boolean debug;
    private final Integer rngSeed;
    private final Integer checkModule0;
    private final double percpuGaussLoad;
    private final double percpuGaussRes;
    private final double correlationGauss;
    private final double tolVar;
    private final double nMinObsFract;
    private final Integer nMinObsInterv;
    private final Integer imputationMeth;
    private final Integer nGaussians;
    private final Integer kOutlier;
    private final double tolerance;
    private final Integer iterations;
    private final double epsilo;
    private final Integer conditionalSampling;
    private final Integer tFlags;
    private final double histo_estremeQ;
    private final double thresGUI;
    private final String nats;
    private final double nnz;
    private final Integer unimod;
    private final Integer modo_inv;
    private final Integer isdeterministic;
    private final Integer isuniform;
    private final Integer opt_GUI;
    private final double Pload_deterministic;
    private final double Qload_deterministic;
    private final double band_uniformPL;
    private final double band_uniformQL;
    private final double band_uniformPGEN;
    private final Integer correlation_fict_uniform;
    private final Integer optFPF;
    private final Integer homothetic;
    private final Integer modelConv;


    public ForecastErrorsAnalyzerConfig(
            Path binariesDir,
            Path runtimeHomeDir,
            Integer checkModule0,
            double percpuGaussLoad,
            double percpuGaussRes,
            double correlationGauss,
            double tolVar,
            double nMinObsFract,
            Integer nMinObsInterv,
            Integer imputationMeth,
            Integer nGaussians,
            Integer kOutlier,
            double tolerance,
            Integer iterations,
            double epsilo,
            Integer conditionalSampling,
            Integer tFlags,
            double histoEstremeQ,
            double thresGUI,
            String nats,
            double nnz,
            Integer unimod,
            Integer modoInv,
            Integer isdeterministic,
            Integer isuniform,
            Integer optGUI,
            double pLoadDeterministic,
            double qLoadDeterministic,
            double bandUniformPL,
            double bandUniformQL,
            double bandUniformPGEN,
            Integer correlationFictUniform,
            Integer optFPF,
            Integer homothetic,
            Integer modelConv,
            Integer rngSeed,
            boolean debug
    ) {
        Objects.requireNonNull(binariesDir, "sampler compiled binaries directory is null");
        Objects.requireNonNull(runtimeHomeDir, "matlab runtime directory is null");

        this.binariesDir = binariesDir;
        this.runtimeHomeDir = runtimeHomeDir;
        this.rngSeed = rngSeed;
        this.checkModule0 = checkModule0;
        this.percpuGaussLoad = percpuGaussLoad;
        this.percpuGaussRes = percpuGaussRes;
        this.correlationGauss = correlationGauss;
        this.tolVar = tolVar;
        this.nMinObsFract = nMinObsFract;
        this.nMinObsInterv = nMinObsInterv;
        this.imputationMeth = imputationMeth;
        this.nGaussians = nGaussians;
        this.kOutlier = kOutlier;
        this.tolerance = tolerance;
        this.iterations = iterations;
        this.epsilo = epsilo;
        this.conditionalSampling = conditionalSampling;
        this.tFlags = tFlags;
        this.histo_estremeQ = histoEstremeQ;
        this.thresGUI = thresGUI;
        this.nats = nats;
        this.debug = debug;
        this.nnz = nnz;
        this.unimod = unimod;
        this.modo_inv = modoInv;
        this.isdeterministic = isdeterministic;
        this.isuniform = isuniform;
        this.opt_GUI = optGUI;
        this.Pload_deterministic = pLoadDeterministic;
        this.Qload_deterministic = qLoadDeterministic;
        this.band_uniformPL = bandUniformPL;
        this.band_uniformQL = bandUniformQL;
        this.band_uniformPGEN = bandUniformPGEN;
        this.correlation_fict_uniform = correlationFictUniform;
        this.optFPF = optFPF;
        this.homothetic = homothetic;
        this.modelConv = modelConv;
    }


    public static ForecastErrorsAnalyzerConfig load() {
        ModuleConfig config = PlatformConfig.defaultConfig().getModuleConfig("forecastErrorsAnalyzer");

        Path binariesDir = config.getPathProperty("binariesDir");
        Path runtimeHomeDir = config.getPathProperty("runtimeHomeDir");
        boolean debug = config.getBooleanProperty("debug", false);
        Integer checkModule0 = Utils.getIntegerFromPropertyOrNull(config, "checkModule0");
        double percpuGaussLoad = config.getDoubleProperty("percpuGaussLoad");
        double percpuGaussRes = config.getDoubleProperty("percpuGaussRes");
        double correlationGauss = config.getDoubleProperty("correlationGauss");
        double tolVar = config.getDoubleProperty("tolvar");
        double nMinObsFract = config.getDoubleProperty("Nmin_obs_fract");
        Integer nMinObsInterv = Utils.getIntegerFromPropertyOrNull(config, "Nmin_obs_interv");
        Integer imputationMeth = Utils.getIntegerFromPropertyOrNull(config, "imputation_meth");
        Integer nGaussians = Utils.getIntegerFromPropertyOrNull(config, "Ngaussians");
        Integer rngSeed = Utils.getIntegerFromPropertyOrNull(config, "rngSeed");
        Integer kOutlier = Utils.getIntegerFromPropertyOrNull(config, "koutlier");
        double tolerance = config.getDoubleProperty("tolerance");
        Integer iterations = Utils.getIntegerFromPropertyOrNull(config, "iterations");
        double epsilo = config.getDoubleProperty("epsilo");
        Integer conditionalSampling = Utils.getIntegerFromPropertyOrNull(config, "conditionalSampling");
        Integer tFlags = Utils.getIntegerFromPropertyOrNull(config, "tFlags");
        double histoEstremeQ = config.getDoubleProperty("histo_estremeQ");
        double thresGUI = config.getDoubleProperty("thresGUI");
        String nats = config.getStringProperty("nats", "All");
        double nnz = config.getDoubleProperty("nnz");
        Integer unimod = Utils.getIntegerFromPropertyOrNull(config, "unimod");
        Integer modoInv = Utils.getIntegerFromPropertyOrNull(config, "modo_inv");
        Integer isdeterministic = Utils.getIntegerFromPropertyOrNull(config, "isdeterministic");
        Integer isuniform = Utils.getIntegerFromPropertyOrNull(config, "isuniform");
        Integer optGUI = Utils.getIntegerFromPropertyOrNull(config, "opt_GUI");
        double pLoadDeterministic = config.getDoubleProperty("Pload_deterministic");
        double qLoadDeterministic = config.getDoubleProperty("Qload_deterministic");
        double bandUniformPL = config.getDoubleProperty("band_uniformPL");
        double bandUniformQL = config.getDoubleProperty("band_uniformQL");
        double bandUniformPGEN = config.getDoubleProperty("band_uniformPGEN");
        Integer correlationFictUniform = Utils.getIntegerFromPropertyOrNull(config, "correlation_fict_uniform");
        Integer optFPF = Utils.getIntegerFromPropertyOrNull(config, "opt_FPF");
        Integer homothetic = Utils.getIntegerFromPropertyOrNull(config, "homothetic");
        Integer modelConv = Utils.getIntegerFromPropertyOrNull(config, "modelConv");

        return new ForecastErrorsAnalyzerConfig(binariesDir, runtimeHomeDir, checkModule0, percpuGaussLoad, percpuGaussRes,
                correlationGauss, tolVar, nMinObsFract, nMinObsInterv, imputationMeth, nGaussians, kOutlier, tolerance,
                iterations, epsilo, conditionalSampling, tFlags, histoEstremeQ, thresGUI, nats,
                nnz, unimod, modoInv, isdeterministic, isuniform, optGUI,
                pLoadDeterministic, qLoadDeterministic, bandUniformPL, bandUniformQL, bandUniformPGEN, correlationFictUniform,
                optFPF, homothetic, modelConv, rngSeed, debug);
    }

    public Path getBinariesDir() {
        return binariesDir;
    }

    public Path getRuntimeHomeDir() {
        return runtimeHomeDir;
    }

    public Integer getCheckModule0() {
        return checkModule0;
    }

    public double getPercpuGaussLoad() {
        return percpuGaussLoad;
    }

    public double getPercpuGaussRes() {
        return percpuGaussRes;
    }

    public double getCorrelationGauss() {
        return correlationGauss;
    }

    public double getTolVar() {
        return tolVar;
    }

    public double getnMinObsFract() {
        return nMinObsFract;
    }

    public Integer getnMinObsInterv() {
        return nMinObsInterv;
    }

    public Integer getImputationMeth() {
        return imputationMeth;
    }

    public Integer getnGaussians() {
        return nGaussians;
    }

    public Integer getkOutlier() {
        return kOutlier;
    }

    public double getTolerance() {
        return tolerance;
    }

    public Integer getIterations() {
        return iterations;
    }

    public double getEpsilo() {
        return epsilo;
    }

    public Integer getConditionalSampling() {
        return conditionalSampling;
    }

    public Integer gettFlags() {
        return tFlags;
    }

    public double getHisto_estremeQ() {
        return histo_estremeQ;
    }

    public double getThresGUI() {
        return thresGUI;
    }

    public String getNats() {
        return nats;
    }

    public Integer getRngSeed() {
        return rngSeed;
    }

    public static Logger getLogger() {
        return LOGGER;
    }

    public boolean isDebug() {
        return debug;
    }

    public double getNnz() {
        return nnz;
    }

    public Integer getUnimod() {
        return unimod;
    }

    public Integer getModo_inv() {
        return modo_inv;
    }

    public Integer getIsdeterministic() {
        return isdeterministic;
    }

    public Integer getIsuniform() {
        return isuniform;
    }

    public Integer getOpt_GUI() {
        return opt_GUI;
    }

    public double getPload_deterministic() {
        return Pload_deterministic;
    }

    public double getQload_deterministic() {
        return Qload_deterministic;
    }

    public double getBand_uniformPL() {
        return band_uniformPL;
    }

    public double getBand_uniformQL() {
        return band_uniformQL;
    }

    public double getBand_uniformPGEN() {
        return band_uniformPGEN;
    }

    public Integer getCorrelation_fict_uniform() {
        return correlation_fict_uniform;
    }

    public Integer getOptFPF() {
        return optFPF;
    }

    public Integer getHomothetic() {
        return homothetic;
    }

    public Integer getModelConv() {
        return modelConv;
    }

    @Override
    public String toString() {
        return "ForecastErrorsAnalyzerConfig [binariesDir=" + binariesDir + ", runtimeHomeDir=" + runtimeHomeDir
                + ", check module0=" + checkModule0
                + ", per cpu gauss load=" + percpuGaussLoad
                + ", per cpu gauss res=" + percpuGaussRes
                + ", correlation gauss=" + correlationGauss
                + ", tolvar=" + tolVar
                + ", Nmin_obs_fract=" + nMinObsFract
                + ", Nmin_obs_interv=" + nMinObsInterv
                + ", imputation_meth=" + imputationMeth
                + ", Ngaussians=" + nGaussians
                + ", koutlier=" + kOutlier
                + ", tolerance=" + tolerance
                + ", iterations=" + iterations
                + ", epsilo=" + epsilo
                + ", conditionalSampling=" + conditionalSampling
                + ", tFlags=" + tFlags
                + ", histo_estremeQ=" + histo_estremeQ
                + ", thresGUI=" + thresGUI
                + ", nats=" + nats
                + ", nnz=" + nnz
                + ", unimod=" + unimod
                + ", modo_invs=" + modo_inv
                + ", isdeterministics=" + isdeterministic
                + ", isuniforms=" + isuniform
                + ", opt_GUIs=" + opt_GUI
                + ", Pload_deterministics=" + Pload_deterministic
                + ", Qload_deterministics=" + Qload_deterministic
                + ", band_uniformPLs=" + band_uniformPL
                + ", band_uniformQLs=" + band_uniformQL
                + ", band_uniformPGENs=" + band_uniformPGEN
                + ", correlation_fict_uniforms=" + correlation_fict_uniform
                + ", opt_FPF=" + optFPF
                + ", homothetic=" + homothetic
                + ", modelConv=" + modelConv
                + ", debug=" + debug + "]";
    }

}
